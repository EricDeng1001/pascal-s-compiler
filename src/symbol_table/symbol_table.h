#pragma once

#include <map>
#include <vector>
#include <deque>
#include <memory>
#include <algorithm>
#include <optional>
#include <set>
#include <variant>
#include <cassert>
#include <type_traits>

#define ENABLE_TEST_FUNCTIONS

namespace PascalSToCPP
{
    enum class BasicType
    {
        INTEGER = 0,
        REAL,
        CHAR,
        BOOLEAN,
        CALLABLE, // procedure, function
        VOID,
        FIRST_VAL = INTEGER,
        LAST_VAL = VOID,
    };

    /**
     * @brief 将给出的枚举值转换为整数
     * 
     * @tparam EnumType 
     * @param enum_val 
     * @return int 
     */
    template <typename EnumType>
    inline constexpr int EnumToInt(const EnumType enum_val) noexcept 
    {
        static_assert(std::is_enum<EnumType>::value, "EnumType 必须为枚举类型");
        return static_cast<int>(enum_val);
    }

    struct Type
    {
        // 判断两个类型是否相等(不包括is_constant, is_ref)
        bool operator==(const Type &rhs) const
        {
            return dimension == rhs.dimension &&
                   type == rhs.type &&
                   std::equal(periods.begin(), periods.end(), rhs.periods.begin(), rhs.periods.end()) &&
                   std::equal(args.begin(), args.end(), rhs.args.begin(), rhs.args.end()) &&
                   ret_type == rhs.ret_type;
        }

        bool operator!=(const Type &rhs) const
        {
            return !((*this) == rhs);
        }

        BasicType type{BasicType::INTEGER};
        bool is_constant{false};
        bool is_ref{false}; // 在作为函数参数的类型时表示参数是否为引用

        // 值表示数组维数, 或表示可调用类型的参数个数
        // 当不为可调用类型时, 值为 0 表示不是数组
        std::size_t dimension{0};

        // 当类型为数组时的下标范围, 其元素个数为 dimension 个
        std::deque<std::pair<int, int>> periods{};

        // 当类型为可调用类型时
        std::deque<Type> args{};
        BasicType ret_type{BasicType::VOID}; // nullopt if procedure

        // 判断类型是否为数组
        bool isArray() const noexcept
        {
            return type != BasicType::CALLABLE && dimension > 0;
        }

        // 判断类型是否为可调用对象
        bool isCallable() const noexcept
        {
            return type == BasicType::CALLABLE;
        }

        // 如果类型为数组, 则返回其各个维度周期的字符串表示(e.g. [a][b][c])
        std::string getArrayPeriodsString() const
        {
            assert(isArray());
	        std::string res;
	        for (const auto [lb, ub]: periods)
            {
                res.append("[")
                   .append(std::to_string(ub - lb))
                   .append("]");
            }
	        return res;
        }

        // 当类型为可调用对象时, 判断是否有返回值
        bool hasRetVal() const noexcept
        {
            assert(type == BasicType::CALLABLE); // 检查是否对不可调用对象检查是否有返回值
            return ret_type != BasicType::VOID;
        }
    };

    struct SymbolBuilder;

    struct Symbol
    {
    public:
        static SymbolBuilder getSymbolBuilder();
        static constexpr std::size_t kHasNoDefAt = -1;

        Symbol(){};
        Symbol(std::string sym_name, const Type &sym_type, const std::size_t def_line_no = kHasNoDefAt)
            : name(std::move(sym_name)), type(sym_type), def_at(def_line_no)
        {
        }

        std::string name{}; // identifier
        Type type{};
        std::size_t def_at{kHasNoDefAt};

        // 判断类型是否为可调用对象
        bool isCallable() const noexcept { return type.isCallable(); }

        // 判断该符号是否已定义但未使用
        bool isDefButNotUsed() const noexcept { return def_at != kHasNoDefAt && ref_at.empty(); }
        
        // 添加引用该符号的行数
        void addRefAt(const std::size_t line_no) { ref_at.insert(line_no); }

        // 获取所有引用该符号的行数
        std::vector<std::size_t> getRefAt() const { return std::vector<std::size_t>(ref_at.begin(), ref_at.end()); }

    private:
        std::set<std::size_t> ref_at{}; // 记录符号被引用的行数
    };

    struct SymbolBuilder
    {
    public:
        // 添加名字
        SymbolBuilder &addName(std::string name);
        SymbolBuilder &setBasicType(const BasicType basic_type) noexcept;
        SymbolBuilder &setConst(const bool is_constant) noexcept;
        SymbolBuilder &setRef(const bool is_ref) noexcept;
        SymbolBuilder &setDimension(const int dimension) noexcept;

        SymbolBuilder &addPeriod(std::pair<int, int> period);
        // 下标从 1 开始
        SymbolBuilder &addPeriod(const std::size_t dimension, const std::pair<int, int> &period);
        SymbolBuilder &addPeriod(const std::size_t dimension, const int low_bound, const int up_bound);

        SymbolBuilder &setRetType(const BasicType basic_type) noexcept;

        SymbolBuilder &addArg(const Type &arg_type);
        SymbolBuilder &addArg(const BasicType basic_type);
        // 下标从 1 开始
        SymbolBuilder &addArg(const std::size_t arg_pos, const Type &arg_type);
        SymbolBuilder &addArg(const std::size_t arg_pos, const BasicType basic_type);

        // 添加定义该符号的行号
        SymbolBuilder &setDefAt(const std::size_t line_no);

        // 返回添加的第一个名字的符号, 若没有添加名字则返回名字为空, 且带有类型的符号
        Symbol Build() const;
        // 返回同一类型的多个不同名字的符号
        std::vector<Symbol> BuildSymbolArray() const;

        // 将 SymbolBuilder 置为初始状态
        void clear();

    private:
        std::vector<std::string> name_;
        std::size_t def_at_{Symbol::kHasNoDefAt};
        Type type_;
    };
    
    inline SymbolBuilder Symbol::getSymbolBuilder() { return SymbolBuilder(); }

    class SymbolTable
    {
    public:
        template <typename T>
        using Vec2 = std::vector<std::vector<T>>;

        // 在当前作用域及全局作用域中按名字寻找符号，若找到则返回指向它的指针，否则返回 nullptr
        Symbol *const getSymbol(const std::string &name);
        const Symbol *const getSymbol(const std::string &name) const;

        // 获取当前作用域中给定符号下标的符号，返回其引用(使用前确保下标合法)
        Symbol &getSymbol(const int symbol_ind);
        const Symbol &getSymbol(const int symbol_ind) const;

        // 如果当前作用域不为全局作用域, 返回其父作用域对应的符号
        const Symbol *const getParentSymbol() const
        {
            assert(!isInGlobalScope());
            return &getSymbolGlobal(scope_ind_);
        }

        // 返回当前作用域是否为全局作用域
        bool isInGlobalScope() const noexcept { return scope_ind_ == kGlobalScopeId; }

        // 获取给定名字在当前作用域的下标
        std::optional<int> getSymbolIndex(const std::string &name) const;

        // 检查给定名字是否已存在于当前作用域
        bool isInScope(const std::string &name) const;

        // 向当前作用域中添加符号，添加成功则返回 true 及符号下标，否则返回 false
        std::pair<bool, int> InsertSymbol(Symbol symbol);

        // 向当前作用域中添加符号，添加成功则返回 true 及符号下标列表，否则返回 false 并保证符号表不变
        std::pair<bool, std::vector<int>> InsertSymbol(const std::vector<Symbol> &symbols);

        // 进入二级作用域，若成功则返回 true，否则返回 false
        bool EnterScope(const int ind);
        bool EnterScope(const std::string &name);

        // 退出二级作用域
        bool ExitScope();

        // 检查传入参数类型是否符合函数定义
        // 参数1：可调用类型符号的名称，若该名称对应的符号类型不可调用则返回 false
        // 参数2：参数列表(调用参数为常量时(数字或字符)填入其 Type, 为标识符时填入其名字)
        bool CheckArgsType(const std::string &name, const std::deque<std::variant<std::string, Type>> &args) const;

        // 检查传入参数类型是否符合函数定义(需要自行获取参数的类型)
        // 参数1：可调用类型符号的名称，若该名称对应的符号类型不可调用则返回 false
        // 参数2：参数类型列表
        bool CheckArgsType(const std::string &name, const std::deque<Type> &arg_types) const;

        // 获取所有已定义却未使用的符号
        std::vector<Symbol> getNotUsedSymbols() const;

        // 获取所有已定义却未使用的符号的名字及其定义行
        std::vector<std::pair<std::string, std::size_t>> getNotUsedSymbolNames() const;

#ifdef ENABLE_TEST_FUNCTIONS
        const int getScopeInd() const noexcept
        {
            return scope_ind_;
        }
        const auto &getGlobalSymbols() const { return global_symbols_; }
        const auto &getGlobalNameIndex() const { return global_name_index_; }
        const auto &getLocalSymbols() const { return local_symbols_; }
        const auto &getLocalSymbols(const int scope_ind) const { return local_symbols_.at(scope_ind); }
        const auto &getLocalNameIndex() const { return local_name_index_; }
        void Clear()
        {
            scope_ind_ = kGlobalScopeId;
            global_symbols_.clear();
            global_name_index_.clear();
            local_name_index_.clear();
            local_symbols_.clear();
        }
#endif

    private:
        Symbol &getSymbolGlobal(const int ind) { return global_symbols_.at(ind); }
        Symbol &getSymbolLocal(const int ind) { return local_symbols_.at(scope_ind_).at(ind); }
        const Symbol &getSymbolGlobal(const int ind) const { return global_symbols_.at(ind); }
        const Symbol &getSymbolLocal(const int ind) const { return local_symbols_.at(scope_ind_).at(ind); }
        bool CheckArgsType(const Type &func_type, const std::deque<Type> &arg_types) const
        {
            // check for basic type
            for (const auto &arg_type : arg_types)
                if (arg_type.type == BasicType::CALLABLE)
                    return false;
                else if (arg_type.dimension != 0)
                    return false;

            return std::equal(func_type.args.begin(), func_type.args.end(), arg_types.begin(), arg_types.end());
        }

        static constexpr int kGlobalScopeId = -1;
        int scope_ind_{kGlobalScopeId};

        std::vector<Symbol> global_symbols_{};
        std::map<std::string, int> global_name_index_{}; // name -> global_index

        Vec2<Symbol> local_symbols_{};
        std::map<std::pair<int, std::string>, int> local_name_index_{}; // <scope_ind, name> -> local_index
    };

    inline SymbolBuilder &SymbolBuilder::addName(std::string name)
    {
        name_.push_back(std::move(name));
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::setBasicType(const BasicType basic_type) noexcept
    {
        type_.type = basic_type;
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::setConst(const bool is_constant) noexcept
    {
        type_.is_constant = is_constant;
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::setRef(const bool is_ref) noexcept
    {
        type_.is_ref = is_ref;
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::setDimension(const int dimension) noexcept
    {
        type_.dimension = dimension;
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::addPeriod(std::pair<int, int> period)
    {
        type_.periods.push_back(std::move(period));
        type_.dimension = std::max(type_.dimension, type_.periods.size());
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::addPeriod(const std::size_t dimension, const std::pair<int, int> &period)
    {
        if (dimension > type_.periods.size())
            type_.periods.resize(dimension);
        type_.periods.at(dimension - 1) = period;
        type_.dimension = std::max(dimension, type_.dimension);
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::addPeriod(const std::size_t dimension, const int low_bound, const int up_bound)
    {
        if (dimension > type_.periods.size())
            type_.periods.resize(dimension);
        type_.periods.at(dimension - 1) = {low_bound, up_bound};
        type_.dimension = std::max(dimension, type_.dimension);
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::setRetType(const BasicType basic_type) noexcept
    {
        type_.ret_type = basic_type;
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::addArg(const Type &arg_type)
    {
        type_.args.push_back(arg_type);
        type_.dimension = std::max(type_.args.size(), type_.dimension);
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::addArg(const BasicType basic_type)
    {
        type_.args.emplace_back();
        type_.args.back().type = basic_type;
        type_.dimension = std::max(type_.args.size(), type_.dimension);
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::addArg(const std::size_t arg_pos, const Type &arg_type)
    {
        if (arg_pos > type_.args.size())
            type_.args.resize(arg_pos);
        type_.args.at(arg_pos - 1) = arg_type;
        type_.dimension = std::max(type_.args.size(), type_.dimension);
        return *this;
    }
    inline SymbolBuilder &SymbolBuilder::addArg(const std::size_t arg_pos, const BasicType basic_type)
    {
        if (arg_pos > type_.args.size())
            type_.args.resize(arg_pos);
        type_.args.at(arg_pos - 1) = Type();
        type_.args.at(arg_pos - 1).type = basic_type;
        type_.dimension = std::max(type_.args.size(), type_.dimension);
        return *this;
    }

    inline SymbolBuilder &SymbolBuilder::setDefAt(const std::size_t line_no)
    {
        def_at_ = line_no;
        return *this;
    }

    inline Symbol SymbolBuilder::Build() const
    {
        return {name_.size() ? name_[0] : "", type_, def_at_};
    }

    inline std::vector<Symbol> SymbolBuilder::BuildSymbolArray() const
    {
        std::vector<Symbol> res;
        std::for_each(name_.begin(), name_.end(), [&](const auto &name) { res.push_back({name, type_, def_at_}); });
        return res;
    }

    inline void SymbolBuilder::clear()
    {
        name_.clear();
        def_at_ = Symbol::kHasNoDefAt;
        type_ = Type();
    }

    inline Symbol &SymbolTable::getSymbol(const int symbol_ind)
    {
        assert(symbol_ind >= 0);
        if (scope_ind_ == kGlobalScopeId)
            return getSymbolGlobal(symbol_ind);
        else
            return getSymbolLocal(symbol_ind);
    }

    inline const Symbol &SymbolTable::getSymbol(const int symbol_ind) const
    {
        assert(symbol_ind >= 0);
        if (scope_ind_ == kGlobalScopeId)
            return getSymbolGlobal(symbol_ind);
        else
            return getSymbolLocal(symbol_ind);
    }

    inline Symbol *const SymbolTable::getSymbol(const std::string &name)
    {
        assert(!name.empty());
        // 若当前处于局部作用域中, 搜索局部作用域
        if (scope_ind_ != kGlobalScopeId)
            if (auto iter = local_name_index_.find({scope_ind_, name}); iter != local_name_index_.end())
                return &getSymbolLocal((*iter).second);

        // 若局部作用域中无该符号, 或者处于全局作用域中, 搜索全局作用域
        if (auto iter = global_name_index_.find(name); iter != global_name_index_.end())
            return &getSymbolGlobal((*iter).second);

        return nullptr;
    }

    inline const Symbol *const SymbolTable::getSymbol(const std::string &name) const
    {
        assert(!name.empty());
        if (scope_ind_ != kGlobalScopeId)
            if (auto iter = local_name_index_.find({scope_ind_, name}); iter != local_name_index_.end())
                return &getSymbolLocal((*iter).second);
        if (auto iter = global_name_index_.find(name); iter != global_name_index_.end())
            return &getSymbolGlobal((*iter).second);
        return nullptr;
    }

    inline std::optional<int> SymbolTable::getSymbolIndex(const std::string &name) const
    {
        assert(!name.empty());
        if (scope_ind_ != kGlobalScopeId)
        {
            if (isInScope(name))
                return local_name_index_.at({scope_ind_, name});
        }
        else
        {
            if (const auto iter = global_name_index_.find(name); iter != global_name_index_.end())
                return (*iter).second;
        }
        return std::nullopt;
    }

    inline bool SymbolTable::isInScope(const std::string &name) const
    {
        assert(!name.empty());
        if (scope_ind_ != kGlobalScopeId)
            return local_name_index_.find({scope_ind_, name}) != local_name_index_.end();
        return global_name_index_.find(name) != global_name_index_.end();
    }

    inline std::pair<bool, int> SymbolTable::InsertSymbol(Symbol symbol)
    {
        std::pair<bool, int> res;
        if (isInScope(symbol.name))
        {
            res = {false, -1};
        }
        else if (scope_ind_ != kGlobalScopeId)
        {
            res = {true, local_symbols_.at(scope_ind_).size()};
            local_name_index_[{scope_ind_, symbol.name}] = res.second;
            local_symbols_.at(scope_ind_).push_back(symbol);
        }
        else
        {
            res = {true, global_symbols_.size()};
            global_name_index_[symbol.name] = res.second;
            global_symbols_.push_back(symbol);
            local_symbols_.emplace_back();
        }
        return res;
    }

    inline std::pair<bool, std::vector<int>> SymbolTable::InsertSymbol(const std::vector<Symbol> &symbols)
    {
        std::tuple backup = {global_symbols_, global_name_index_, local_name_index_, local_symbols_};
        std::pair<bool, std::vector<int>> res{true, {}};
        for (const auto &symbol : symbols)
        {
            if (auto [is_suc, ind] = InsertSymbol(symbol); is_suc)
            {
                res.second.push_back(ind);
            }
            else
            {
                res = {false, {}};
                auto &[gs, gni, lni, ls] = backup;
                global_name_index_.swap(gni);
                global_symbols_.swap(gs);
                local_name_index_.swap(lni);
                local_symbols_.swap(ls);
                break;
            }
        }
        return res;
    }

    inline bool SymbolTable::EnterScope(const int ind)
    {
        if (scope_ind_ != kGlobalScopeId)
            return false;
        scope_ind_ = ind;
        return true;
    }
    inline bool SymbolTable::EnterScope(const std::string &name)
    {
        assert(!name.empty());
        if (scope_ind_ != kGlobalScopeId)
            return false;
        if (!isInScope(name))
            return false;
        scope_ind_ = getSymbolIndex(name).value();
        return true;
    }

    inline bool SymbolTable::ExitScope()
    {
        if (scope_ind_ == kGlobalScopeId)
            return false;
        scope_ind_ = kGlobalScopeId;
        return true;
    }

    inline bool SymbolTable::CheckArgsType(const std::string &name, const std::deque<std::variant<std::string, Type>> &args) const
    {
        const auto symbol = getSymbol(name);
        if (!symbol || symbol->type.type != BasicType::CALLABLE)
            return false;
        std::deque<Type> arg_types;
        for (const auto &arg : args)
        {
            if (std::holds_alternative<std::string>(arg))
            {
                const auto arg_symbol = getSymbol(std::get<std::string>(arg));
                if (!arg_symbol)
                    return false;
                arg_types.push_back(arg_symbol->type);
            }
            else
            {
                arg_types.push_back(std::get<Type>(arg));
            }
        }
        return CheckArgsType(symbol->type, arg_types);
    }

    inline bool SymbolTable::CheckArgsType(const std::string &name, const std::deque<Type> &arg_types) const
    {
        const auto symbol = getSymbol(name);
        if (!symbol || symbol->type.type != BasicType::CALLABLE)
            return false;
        return CheckArgsType(symbol->type, arg_types);
    }

    inline std::vector<Symbol> SymbolTable::getNotUsedSymbols() const
    {
        std::vector<Symbol> res;
        std::copy_if(global_symbols_.begin(), global_symbols_.end(), std::back_inserter(res)
            ,[](const auto &i){ return i.isDefButNotUsed(); });
        for (const auto &local_symbols : local_symbols_)
            std::copy_if(local_symbols.begin(), local_symbols.end(), std::back_inserter(res), 
                [](const auto &i){ return i.isDefButNotUsed(); });
        return res;
    }

    inline std::vector<std::pair<std::string, std::size_t>> SymbolTable::getNotUsedSymbolNames() const
    {
        std::vector<std::pair<std::string, std::size_t>> res;
        for (const auto &global_symbol : global_symbols_)
            if (global_symbol.isDefButNotUsed())
                res.emplace_back(global_symbol.name, global_symbol.def_at);
        for (const auto &local_symbols : local_symbols_)
            for (const auto &local_symbol : local_symbols)
                if (local_symbol.isDefButNotUsed())
                    res.emplace_back(local_symbol.name, local_symbol.def_at);        
        return res;
    }
} // namespace PascalSToCPP
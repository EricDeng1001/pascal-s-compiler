#include <random>

#include <gtest/gtest.h>
#include "symbol_table.h"

using namespace PascalSToCPP;

Type GetRandomType(int depth = 0)
{
    static constexpr int basic_type_min = EnumToInt(BasicType::FIRST_VAL);
    static constexpr int basic_type_max = EnumToInt(BasicType::LAST_VAL);
    static constexpr int null_ret_type = basic_type_max + 1;
    static constexpr float RussianRoulette = 0.5;

    static std::random_device rd;
    static std::mt19937 rng(rd());
    static std::uniform_int_distribution<std::size_t> dimension_dist(0, 30);
    static std::uniform_int_distribution<int> basic_type_dist(basic_type_min, basic_type_max);
    static std::uniform_int_distribution<int> binary_dist(0, 1);
    static std::uniform_int_distribution<int> low_bound_dist(-100, 100);
    static std::uniform_int_distribution<int> up_bound_dist(-50, 150);
    static std::uniform_int_distribution<int> ret_type_dist(basic_type_min, basic_type_max);
    static std::uniform_real_distribution<float> rr_probility(.0f, 1.f);

    Type res = Type();
    if (rr_probility(rng) >= RussianRoulette || depth > 15)
        return res;
    res.type = static_cast<BasicType>(basic_type_dist(rng));
    res.dimension = dimension_dist(rng);
    if (res.dimension > 0)
    {
        if (res.type == BasicType::CALLABLE)
        {
            int ret_type_temp = ret_type_dist(rng);
            if (ret_type_temp != null_ret_type)
                res.ret_type = static_cast<BasicType>(ret_type_temp);
            for (uint i = 0; i < res.dimension; i++)
            {
                res.args.push_back(GetRandomType(depth + 1));
            }
        }
        else
        {
            for (uint i = 0; i < res.dimension; i++)
            {
                int lb = low_bound_dist(rng);
                int ub = up_bound_dist(rng);
                while (ub < lb)
                    ub = up_bound_dist(rng);
                res.periods.push_back({lb, ub});
            }
        }
    }
    return res;
}

TEST(Test, SymbolBuilderTestBasic)
{
    Type test_type;
    test_type.dimension = 1;
    test_type.type = BasicType::INTEGER;
    test_type.ret_type = BasicType::BOOLEAN;

    auto symbol = Symbol::getSymbolBuilder().addName("test")
                                          .setBasicType(BasicType::INTEGER)
                                          .setConst(true)
                                          .setRef(true)
                                          .setDimension(1)
                                          .setRetType(BasicType::BOOLEAN)
                                          .setDefAt(100)
                                          .Build();
    EXPECT_EQ(symbol.name, "test");
    EXPECT_EQ(symbol.type, test_type);
    EXPECT_EQ(symbol.type.periods.size(), 0);
    EXPECT_EQ(symbol.type.args.size(), 0);
    EXPECT_EQ(symbol.type.is_constant, true);
    EXPECT_EQ(symbol.type.is_ref, true);
    EXPECT_EQ(symbol.type.ret_type, BasicType::BOOLEAN);
    EXPECT_EQ(symbol.def_at, 100);
    EXPECT_EQ(symbol.getRefAt().empty(), true);
}

TEST(Test, SymbolBuilderTestPeriod)
{
    std::deque<std::pair<int, int>> test_periods{{1,2}, {-1,3}, {3,4}, {5,8}};
    auto symbol = Symbol::getSymbolBuilder().addPeriod({1,2})
                               .addPeriod({-1,3})
                               .addPeriod({3,4})
                               .addPeriod({5,8})
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.dimension, 4);
    EXPECT_EQ(symbol.type.periods.size(), 4);
    EXPECT_EQ(symbol.type.args.size(), 0);
    for (uint i = 0; i < test_periods.size(); i++)
        EXPECT_EQ(symbol.type.periods[i], test_periods[i]);

    symbol = Symbol::getSymbolBuilder().addPeriod(4, {5, 8})
                               .addPeriod(2, {-1, 3})
                               .addPeriod(3, {3, 4})
                               .addPeriod(1, {1, 2})
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.dimension, 4);
    EXPECT_EQ(symbol.type.periods.size(), 4);
    EXPECT_EQ(symbol.type.args.size(), 0);
    for (uint i = 0; i < test_periods.size(); i++)
        EXPECT_EQ(symbol.type.periods[i], test_periods[i]);

    symbol = Symbol::getSymbolBuilder().addPeriod(4, 5, 8)
                               .addPeriod(2, -1, 3)
                               .addPeriod(3, 3, 4)
                               .addPeriod(1, 1, 2)
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.dimension, 4);
    EXPECT_EQ(symbol.type.periods.size(), 4);
    EXPECT_EQ(symbol.type.args.size(), 0);
    for (uint i = 0; i < test_periods.size(); i++)
        EXPECT_EQ(symbol.type.periods[i], test_periods[i]); 
}

TEST(Test, SymbolBuilderTestAddArgs)
{
    std::deque<Type> test_types(5, Type());
    test_types[0].type = BasicType::INTEGER;
    test_types[1].type = BasicType::BOOLEAN;
    test_types[2].type = BasicType::CALLABLE;
    test_types[3].type = BasicType::CHAR;
    test_types[4].type = BasicType::REAL;

    auto symbol = Symbol::getSymbolBuilder().addArg(BasicType::INTEGER)
                               .addArg(BasicType::BOOLEAN)
                               .addArg(BasicType::CALLABLE)
                               .addArg(BasicType::CHAR)
                               .addArg(BasicType::REAL)
                               .setBasicType(BasicType::CALLABLE)
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.type, BasicType::CALLABLE);
    EXPECT_EQ(symbol.type.dimension, 5);
    EXPECT_EQ(symbol.type.periods.size(), 0);
    EXPECT_EQ(symbol.type.args.size(), 5);
    for (uint i = 0; i < test_types.size(); i++)
        EXPECT_EQ(symbol.type.args[i], test_types[i]); 
    
    symbol = Symbol::getSymbolBuilder().addArg(test_types[0])
                               .addArg(test_types[1])
                               .addArg(test_types[2])
                               .addArg(test_types[3])
                               .addArg(test_types[4])
                               .setBasicType(BasicType::CALLABLE)
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.type, BasicType::CALLABLE);
    EXPECT_EQ(symbol.type.dimension, 5);
    EXPECT_EQ(symbol.type.periods.size(), 0);
    EXPECT_EQ(symbol.type.args.size(), 5);
    for (uint i = 0; i < test_types.size(); i++)
        EXPECT_EQ(symbol.type.args[i], test_types[i]);
    
    symbol = Symbol::getSymbolBuilder().addArg(2, BasicType::BOOLEAN)
                               .addArg(4, BasicType::CHAR)
                               .addArg(3, BasicType::CALLABLE)
                               .addArg(5, BasicType::REAL)
                               .addArg(1, BasicType::INTEGER)
                               .setBasicType(BasicType::CALLABLE)
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.type, BasicType::CALLABLE);
    EXPECT_EQ(symbol.type.dimension, 5);
    EXPECT_EQ(symbol.type.periods.size(), 0);
    EXPECT_EQ(symbol.type.args.size(), 5);
    for (uint i = 0; i < test_types.size(); i++)
        EXPECT_EQ(symbol.type.args[i], test_types[i]); 

    symbol = Symbol::getSymbolBuilder().addArg(3, test_types[2])
                               .addArg(4, test_types[3])
                               .addArg(1, test_types[0])
                               .addArg(5, test_types[4])
                               .addArg(2, test_types[1])
                               .setBasicType(BasicType::CALLABLE)
                               .Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type.type, BasicType::CALLABLE);
    EXPECT_EQ(symbol.type.dimension, 5);
    EXPECT_EQ(symbol.type.periods.size(), 0);
    EXPECT_EQ(symbol.type.args.size(), 5);
    for (uint i = 0; i < test_types.size(); i++)
        EXPECT_EQ(symbol.type.args[i], test_types[i]); 
}

TEST(Test, SymbolBuilderTestBuildArr)
{
    auto builder = Symbol::getSymbolBuilder();
    builder.addName("test");
    builder.setBasicType(BasicType::CALLABLE);
    builder.setConst(true);
    auto symbol = builder.Build();
    EXPECT_EQ(symbol.name, "test");
    EXPECT_EQ(symbol.type.type, BasicType::CALLABLE);
    EXPECT_EQ(symbol.type.is_constant, true);
    EXPECT_EQ(symbol.type.is_ref, false);
    EXPECT_EQ(symbol.type.args.size(), 0);
    EXPECT_EQ(symbol.type.dimension, 0);
    EXPECT_EQ(symbol.type.periods.size(), 0);

    builder.clear();
    symbol = builder.Build();
    EXPECT_EQ(symbol.name, "");
    EXPECT_EQ(symbol.type, Type());

    std::vector<std::string> names = {"asdf", "qwer", "zxcv", "tyui", "ghjk", "bnm,"};
    for (const auto &name : names)
        builder.addName(name);
    builder.setDefAt(100);
    auto symbols = builder.BuildSymbolArray();
    EXPECT_EQ(symbols.size(), names.size());
    for (uint i = 0; i < symbols.size(); i++)
    {
        EXPECT_EQ(symbols[i].name, names[i]);
        EXPECT_EQ(symbols[i].type, Type());
        EXPECT_EQ(symbols[i].def_at, 100);
    }
}

TEST(Test, TypeEquivalenceTest)
{
    for (int i = 0; i < 1000; i++)
    {
        Type type1 = GetRandomType();
        Type type2 = type1;
        EXPECT_EQ(type1, type2);
        if (type1.dimension)
        {
            if (type1.type == BasicType::CALLABLE)
            {
                type2.args.push_back(Type());
            }
            else
            {
                type2.periods.pop_back();
            }
            EXPECT_NE(type1, type2);
        }
    }
}

class SymbolsTableTest : public testing::Test
{
protected:
    virtual void SetUp() override
    {
        for (int i = 0; i < 26; i++)
        {
            Symbol symbol;
            symbol.name.push_back('a' + i);
            symbol.type = Type();
            symbols.push_back(symbol);
        }
        std::random_shuffle(symbols.begin(), symbols.end());
        for (uint i = 0; i < symbols.size(); i++)
        {
            lut[symbols.at(i).name] = i;
        }
        
    }

    std::vector<Symbol> symbols;
    std::map<std::string, int> lut;
};

TEST_F(SymbolsTableTest, SymbolTableInitTest)
{
    SymbolTable table{};
    EXPECT_EQ(table.getScopeInd(), -1);
    EXPECT_EQ(table.getGlobalSymbols().empty(), true);
    EXPECT_EQ(table.getLocalSymbols().empty(), true);
    EXPECT_EQ(table.getGlobalNameIndex().empty(), true);
    EXPECT_EQ(table.getLocalNameIndex().empty(), true);
}

TEST_F(SymbolsTableTest, SymbolTableAddGetGlobalSymbolsTest)
{
    SymbolTable table;
    for (uint i = 0; i < symbols.size(); i++)
    {
        const auto [is_suc, ind] = table.InsertSymbol(symbols.at(i));
        EXPECT_EQ(is_suc, true);
        EXPECT_EQ(ind, i);
    }
    EXPECT_EQ(table.getScopeInd(), -1);
    EXPECT_EQ(table.getGlobalSymbols().size(), 26);
    EXPECT_EQ(table.getGlobalNameIndex().size(), 26);
    EXPECT_EQ(table.getLocalNameIndex().empty(), true);
    EXPECT_EQ(table.getLocalSymbols().size(), 26);
    for (const auto &[name, ind] : table.getGlobalNameIndex())
    {
        EXPECT_EQ(ind, lut.at(name));
    }

    for (int i = 0; i < 26; i++)
    {
        std::string target_name;
        target_name.push_back('a' + i);
        auto ind = table.getSymbolIndex(target_name);
        auto is_in_scope = table.isInScope(target_name);
        EXPECT_EQ(ind.has_value(), true);
        EXPECT_EQ(ind.value(), lut.at(target_name));
        EXPECT_EQ(is_in_scope, true);
    }

    {
        auto ind = table.getSymbolIndex("what");
        auto is_in_scope = table.isInScope("what");
        EXPECT_EQ(ind.has_value(), false);
        EXPECT_EQ(is_in_scope, false);
    }

    for (int i = 0; i < 26; i++)
    {
        const auto &symbol = table.getSymbol(i);
        EXPECT_EQ(symbol.name, symbols.at(i).name);
        EXPECT_EQ(symbol.type, symbols.at(i).type);
    }

    for (int i = 0; i < 26; i++)
    {
        std::string target_name;
        target_name.push_back('a' + i);
        const auto symbol = table.getSymbol(target_name);
        EXPECT_NE(symbol, nullptr);
        EXPECT_EQ(symbol->name, target_name);
    }
    // reset
    table.Clear();

    const auto [is_suc, ind_vec] = table.InsertSymbol(symbols);
    EXPECT_EQ(is_suc, true);
    EXPECT_EQ(table.getScopeInd(), -1);
    EXPECT_EQ(table.getGlobalSymbols().size(), 26);
    EXPECT_EQ(table.getGlobalNameIndex().size(), 26);
    EXPECT_EQ(table.getLocalNameIndex().empty(), true);
    EXPECT_EQ(table.getLocalSymbols().size(), 26);

    EXPECT_EQ(ind_vec.size(), symbols.size());
    for (uint i = 0; i < ind_vec.size(); i++)
        EXPECT_EQ(ind_vec.at(i), i);

    for (const auto &[name, ind] : table.getGlobalNameIndex())
        EXPECT_EQ(ind, lut.at(name));

    for (int i = 0; i < 26; i++)
    {
        std::string target_name;
        target_name.push_back('a' + i);
        auto ind = table.getSymbolIndex(target_name);
        auto is_in_scope = table.isInScope(target_name);
        EXPECT_EQ(ind.has_value(), true);
        EXPECT_EQ(ind.value(), lut.at(target_name));
        EXPECT_EQ(is_in_scope, true);
    }

    {
        auto ind = table.getSymbolIndex("what");
        auto is_in_scope = table.isInScope("what");
        EXPECT_EQ(ind.has_value(), false);
        EXPECT_EQ(is_in_scope, false);
    }

    for (int i = 0; i < 26; i++)
    {
        const auto &symbol = table.getSymbol(i);
        EXPECT_EQ(symbol.name, symbols.at(i).name);
        EXPECT_EQ(symbol.type, symbols.at(i).type);
    }

    for (int i = 0; i < 26; i++)
    {
        std::string target_name;
        target_name.push_back('a' + i);
        const auto symbol = table.getSymbol(target_name);
        EXPECT_NE(symbol, nullptr);
        EXPECT_EQ(symbol->name, target_name);
    }

    EXPECT_EQ(table.InsertSymbol(symbols[1]).first, false);
    EXPECT_EQ(table.InsertSymbol(symbols).first, false);
    EXPECT_EQ(table.getScopeInd(), -1);
    EXPECT_EQ(table.getGlobalSymbols().size(), 26);
    EXPECT_EQ(table.getGlobalNameIndex().size(), 26);
    EXPECT_EQ(table.getLocalNameIndex().empty(), true);
    EXPECT_EQ(table.getLocalSymbols().size(), 26);
}

TEST_F(SymbolsTableTest, SymbolTestAddGetLocalSymbolTest)
{
    SymbolTable table;
    EXPECT_EQ(table.InsertSymbol(symbols).first, true);
    EXPECT_EQ(table.getLocalSymbols().size(), symbols.size());
    for (int i = 0; i < 26; i++)
    {
        std::string target_name;
        target_name.push_back('a' + i);
        EXPECT_EQ(table.EnterScope(i), true);
        EXPECT_EQ(table.EnterScope(i), false);
        EXPECT_EQ(table.ExitScope(), true);
        EXPECT_EQ(table.ExitScope(), false);
        EXPECT_EQ(table.EnterScope(target_name), true);
        EXPECT_EQ(table.ExitScope(), true);
    }

    EXPECT_EQ(table.EnterScope(0), true);
    
    // find global symbols in local scope
    for (int i = 0; i < 26; i++)
    {
        std::string target_name;
        target_name.push_back('a' + i);
        const auto symbol = table.getSymbol(target_name);
        EXPECT_NE(symbol, nullptr);
        EXPECT_EQ(table.isInScope(target_name), false);
    }

    // local symbol and global symbol with same name
    {
        auto temp_symbol = Symbol::getSymbolBuilder().addName("b")
                              .setBasicType(BasicType::BOOLEAN)
                              .Build();
        EXPECT_NE(temp_symbol.type, Type());
        auto is_suc = table.InsertSymbol(temp_symbol);
        EXPECT_EQ(is_suc.first, true);
        const auto symbol = table.getSymbol("b");
        EXPECT_NE(symbol, nullptr);
        EXPECT_NE(symbol->type, Type());
        EXPECT_EQ(table.isInScope("b"), true);
        const auto ind = table.getSymbolIndex("b");
        EXPECT_EQ(ind.has_value(), true);
        EXPECT_EQ(ind.value(), 0);
        EXPECT_EQ(table.getLocalSymbols(0).size(), 1);
    }

    EXPECT_EQ(table.InsertSymbol(Symbol::getSymbolBuilder().addName("bbb").Build()).first, true);
    EXPECT_EQ(table.ExitScope(), true);
    EXPECT_EQ(table.isInScope("bbb"), false);
}

TEST(ArgTest, CheckArgsTypeTest)
{
    SymbolTable table;
    auto func_symbol = Symbol::getSymbolBuilder().setBasicType(BasicType::CALLABLE)
                                .addArg(BasicType::INTEGER)
                                .addArg(BasicType::CHAR)
                                .addArg(BasicType::REAL)
                                .addName("Func")
                                .Build();
    
    auto arg_symbols = Symbol::getSymbolBuilder().addName("a")
                                        .addName("b")
                                        .addName("c")
                                        .setBasicType(BasicType::INTEGER)
                                        .BuildSymbolArray();
    arg_symbols[1].type.type = BasicType::CHAR;
    arg_symbols[2].type.type = BasicType::REAL;

    EXPECT_EQ(table.InsertSymbol(func_symbol).first, true);
    EXPECT_EQ(table.InsertSymbol(arg_symbols).first, true);
    {
        std::deque<Type> test_args;
        for (uint i = 0; i < arg_symbols.size(); i++)
            test_args.push_back(arg_symbols[i].type);

        EXPECT_EQ(table.CheckArgsType("unc", test_args), false);
        EXPECT_EQ(table.CheckArgsType("Func", test_args), true);
        test_args.back().type = BasicType::INTEGER;
        EXPECT_EQ(table.CheckArgsType("Func", test_args), false);
        test_args.pop_back();
        EXPECT_EQ(table.CheckArgsType("Func", test_args), false);
        test_args.push_back(arg_symbols[2].type);
        test_args.push_back(Type());
        EXPECT_EQ(table.CheckArgsType("Func", test_args), false);
    }

    {
        std::deque<std::variant<std::string, Type>> args;
        args.emplace_back("a");
        args.emplace_back(arg_symbols[1].type);
        args.emplace_back("c");
        EXPECT_EQ(table.CheckArgsType("unc", args), false);
        EXPECT_EQ(table.CheckArgsType("Func", args), true);
        args.back() = arg_symbols[2].type;
        EXPECT_EQ(table.CheckArgsType("Func", args), true);
        args.back() = "Func";
        EXPECT_EQ(table.CheckArgsType("Func", args), false);
        args.pop_back();
        EXPECT_EQ(table.CheckArgsType("Func", args), false);
        args.push_back("a");
        args.push_back("c");
        EXPECT_EQ(table.CheckArgsType("Func", args), false);
    }

    {
        auto void_func_symbol = Symbol::getSymbolBuilder().addName("VoidFunc")
                                    .setBasicType(BasicType::CALLABLE)
                                    .Build();
        EXPECT_EQ(table.InsertSymbol(void_func_symbol).first, true);
        EXPECT_EQ(table.CheckArgsType("VoidFunc", std::deque<Type>{}), true);
        EXPECT_EQ(table.CheckArgsType("VoidFunc", std::deque<std::variant<std::string, Type>>{}), true);
        EXPECT_EQ(table.CheckArgsType("VoidFunc", std::deque<Type>{arg_symbols[0].type}), false);
        EXPECT_EQ(table.CheckArgsType("VoidFunc", std::deque<std::variant<std::string, Type>>{"a", arg_symbols[0].type}), false);
    }
}

TEST(Symbol, SymbolRefAtDefAtTest)
{
    Symbol symbol = Symbol::getSymbolBuilder().addName("test")
                                      .setDefAt(100)
                                      .Build();
    EXPECT_EQ(symbol.isDefButNotUsed(), true);
    symbol.addRefAt(100);
    symbol.addRefAt(101);
    EXPECT_EQ(symbol.getRefAt().size(), 2);
    EXPECT_EQ(symbol.isDefButNotUsed(), false);
}

int main(int argc, char *argv[])
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
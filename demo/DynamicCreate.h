//
//  DynamicCreate.hpp
//  Hippy
//
//  Created by howlpan on 2018/11/23.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#ifndef DynamicCreate_hpp
#define DynamicCreate_hpp

#include <stdio.h>
#include <string>
#include <iostream>
#include <typeinfo>
#include <memory>
#include <unordered_map>
#include <cxxabi.h>


class Base
{
public:
    Base(){std::cout << "Base construct" << std::endl;}
    virtual ~Base(){};
    virtual void TestFunc()
    {
        std::cout << "TestFunc" << std::endl;
    }
};

template <typename ...Targs>
class ClassFactory {
public:
    static ClassFactory* Instance()
    {
        std::cout << "static ClassFactory* Instance()" << std::endl;
        if (nullptr == m_pClassFactory) {
            m_pClassFactory = new ClassFactory();
        }
        
        return m_pClassFactory;
    }
    
    virtual ~ClassFactory() {};
    
    bool Regist(const std::string& strTypeName, std::function<Base*(Targs&&... args)> pFunc) {
        std::cout << "Regist(const std::string& strTypeName, std::function<Base*(Targs&&.. args)> pFunc)" << std::endl;
        if (nullptr == pFunc) {
            return false;
        }
        
        std::string strRealTypeName = strTypeName;
        bool bReg = m_mapCreateFunction.insert(std::make_pair(strRealTypeName, pFunc)).second;
        return bReg;
    }
    
    Base* Create(const std::string& strTypeName, Targs&&... args) {
        std::cout << "Create(const std::string& strTypeName, Targs&&... args)" << std::endl;
        auto iter = m_mapCreateFunction.find(strTypeName);
        if (iter == m_mapCreateFunction.end()) {
            return nullptr;
        }
        
        return iter->second(std::forward<Targs>(args)...);
    }
    
private:
    ClassFactory() {std::cout << "ClassFactory construce" << std::endl;};
    static ClassFactory<Targs...> * m_pClassFactory;
    std::unordered_map<std::string, std::function<Base *(Targs&&...)>> m_mapCreateFunction;
};

template<typename ...Targs>
ClassFactory<Targs...>* ClassFactory<Targs...>::m_pClassFactory = nullptr;

template <typename T, typename ...Targs>
class DynamicCreator {
public:
    struct Register
    {
        Register() {
            std::cout << "DynamicCreator.Register construct" << std::endl;
            char *szDemangleName = nullptr;
            std::string strTypeName;
            
            szDemangleName = abi::__cxa_demangle(typeid(T).name(), nullptr, nullptr, nullptr);

            if (nullptr != szDemangleName) {
                strTypeName = szDemangleName;
                free(szDemangleName);
            }
            
            ClassFactory<Targs...>::Instance()->Regist(strTypeName, CreateObject);
        }
        
        inline void do_nothing() const {};
    };
    
    DynamicCreator()
    {
        std::cout << "DynamicCreator construct" << std::endl;
        m_oRegister.do_nothing();
    }
    
    virtual ~DynamicCreator() {m_oRegister.do_nothing();};
    
    static T* CreateObject(Targs&&... args)
    {
        std::cout << "static Base * DynamicCreater::CreateObject(Targs... args)" << std::endl;
        return new T(std::forward<Targs>(args)...);
    }
    
    virtual void Say()
    {
        std::cout << "DynamicCreator Say" << std::endl;
    }
    
    static Register m_oRegister;
};

template<typename T, typename ...Targs>
typename DynamicCreator<T, Targs...>::Register DynamicCreator<T, Targs...>::m_oRegister;


class Test1: public Base, public DynamicCreator<Test1>
{
public:
    Test1(){std::cout << "Create Test1 " << std::endl;}
    virtual void TestFunc()
    {
        std::cout << "Test1" << std::endl;
    }
};

class Test2: public Base, DynamicCreator<Test2, std::string, int>
{
public:
    Test2(const std::string& strType, int iSeq){std::cout << "Create Test2 " << strType << " with seq " << iSeq << std::endl;}
    virtual void TestFunc()
    {
        std::cout << "Test2" << std::endl;
    }
};

class Interface
{
public:
    template<typename ...Targs>
    Base * CreateClass(const std::string& strTypeName, Targs&&... args)
    {
        Base *p = ClassFactory<Targs...>::Instance()->Create(strTypeName, std::forward<Targs>(args)...);
        return p;
    }
};
#endif /* DynamicCreate_hpp */



/**
 * test:
 
Interface i;
Base* pNull = i.CreateClass("null");
if (pNull) {

}
Base* p1 = i.CreateClass("Test1");
p1->TestFunc();
Base* p2 = i.CreateClass(std::string("Test2"), std::string("Test2"), 10);
p2->TestFunc();

*/

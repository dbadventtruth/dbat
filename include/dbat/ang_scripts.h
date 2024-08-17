#pragma once
#include "structs.h"
#include "contextmgr/contextmgr.h"
#include "scriptstdstring/scriptstdstring.h"
#include "scriptarray/scriptarray.h"
#include "scriptdictionary/scriptdictionary.h"
#include "scriptmath/scriptmath.h"
#include "scriptmath/scriptmathcomplex.h"
#include "refs.h"

namespace ang {
    
    extern CContextMgr* contextMgr;

    extern void initAngelScript();

    template <typename T>
    void constructObject(void *memory) {
        new (memory) T();
    }

    template <typename T>
    void destructObject(void *memory) {
        ((T*)memory)->~T();
    }

    template <typename T>
    void constructObjectCopy(void *memory, const T& other) {
        new (memory) T(other); // Calls the copy constructor of T
    }

    template <typename T>
    void assignObject(T* self, const T& other) {
        *self = other;
    }

    template<typename T>
    void registerUnitBase(const char* name) {
        engine->RegisterObjectMethod(name, "bool isValid() const", asFUNCTION(ref::isValid<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "string getName()", asFUNCTION(ref::getName<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "string getShortDescription()", asFUNCTION(ref::getShortDescription<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "string getRoomDescription()", asFUNCTION(ref::getRoomDescription<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "string getLookDescription()", asFUNCTION(ref::getLookDescription<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "void setVarCharacter(const string &in, Character)", asFUNCTION(ref::setVarCharacter<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "Character getVarCharacter(const string &in) const", asFUNCTION(ref::getVarCharacter<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "void clearVarCharacter(const string &in)", asFUNCTION(ref::clearVarCharacter<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "void setVarObject(const string &in, Object)", asFUNCTION(ref::setVarObject<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "Object getVarObject(const string &in) const", asFUNCTION(ref::getVarObject<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "void clearVarObject(const string &in)", asFUNCTION(ref::clearVarObject<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "void setVarRoom(const string &in, Room)", asFUNCTION(ref::setVarRoom<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "Room getVarRoom(const string &in) const", asFUNCTION(ref::getVarRoom<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "void clearVarRoom(const string &in)", asFUNCTION(ref::clearVarRoom<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "void setVarString(const string &in, const string &in)", asFUNCTION(ref::setVarString<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "string getVarString(const string &in) const", asFUNCTION(ref::getVarString<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "void clearVarString(const string &in)", asFUNCTION(ref::clearVarString<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "void setVarInt(const string &in, int64)", asFUNCTION(ref::setVarInt<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "int64 getVarInt(const string &in) const", asFUNCTION(ref::getVarInt<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "void clearVarInt(const string &in)", asFUNCTION(ref::clearVarInt<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "void setVarDouble(const string &in, double)", asFUNCTION(ref::setVarDouble<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "double getVarDouble(const string &in) const", asFUNCTION(ref::getVarDouble<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "void clearVarDouble(const string &in)", asFUNCTION(ref::clearVarDouble<T>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectMethod(name, "array<Object>@ getContents() const", asFUNCTION(ref::getContents<T>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, "Object findObjectVnum(int64) const", asFUNCTION(ref::findObjectVnum<T>), asCALL_CDECL_OBJFIRST);
    }

    

    template<typename T>
    void registerThingBase(const char* name) {
        // Register all base methods.
        registerUnitBase<T>(name);

        // More methods
        engine->RegisterObjectMethod(name, "Room getRoom() const", asFUNCTION(ref::getRoom<T>), asCALL_CDECL_OBJFIRST);
    }

    template<typename TrivType>
    void registerTrivialConDec(const char* name) {
        engine->RegisterObjectBehaviour(name, asBEHAVE_CONSTRUCT, "void f()", asFUNCTION(constructObject<TrivType>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectBehaviour(name, asBEHAVE_DESTRUCT, "void f()", asFUNCTION(destructObject<TrivType>), asCALL_CDECL_OBJFIRST);

        engine->RegisterObjectBehaviour(name, asBEHAVE_CONSTRUCT, fmt::format("void f(const {} &in)", name).c_str(),
            asFUNCTION(constructObjectCopy<TrivType>), asCALL_CDECL_OBJFIRST);
        engine->RegisterObjectMethod(name, fmt::format("{} &opAssign(const {} &in)", name, name).c_str(),
            asFUNCTION(assignObject<TrivType>), asCALL_CDECL_OBJFIRST);
    }

    template<typename EnumType>
    void registerEnumClass(const char* name) {
        engine->RegisterEnum(name);
        magic_enum::enum_for_each<EnumType>([&] (auto val) {
        constexpr EnumType v = val;
        auto enumName = std::string(magic_enum::enum_name(v));
        engine->RegisterEnumValue(name, enumName.c_str(), static_cast<int>(v));
        });
    }

    class ASEvent;
    class ASEventPrototype {
        friend class ASEvent;
        public:
            ASEventPrototype(const std::string &id);
            ~ASEventPrototype();

            const std::string& getId() const;

            asIScriptModule* getModule();

            void setCode(const std::vector<std::pair<std::string, std::string>> &code);

            void registerContext(ASEvent* context);

            void unregisterContext(ASEvent* context);

            void setEventType(uint32_t eventType);
            
            uint32_t getEventType() const;

        protected:
            void buildModule();
            std::vector<std::pair<std::string, std::string>> code;
            std::string id;
            asIScriptModule* module;
            std::unordered_set<ASEvent*> contexts;
            uint32_t eventTypes{0}; // a bitvector.
    };

    using ScriptResult = std::variant<int, float, std::string, CharRef, ObjRef, RoomRef>;

    extern std::unordered_set<ASEvent*> suspendedContexts;

    class ASEvent {
        friend class ASEventPrototype;
        public:
            static InstanceMap<ASEvent> instances;
            ASEvent(UID owner, int64_t id, time_t generation, ASEventPrototype* prototype);

            ~ASEvent();

            void reset();

            void prepare();

            bool isReady() const;

            std::optional<ScriptResult> execute();

            asIScriptContext* getContext() const;
            
            ASEventPrototype* getPrototype() const;

            //ASERef ref() const;

            UID getOwner() const;

        protected:

            std::string debugName() const;
            void abort();

            void lineCallback(asIScriptContext* ctx);

            UID owner;
            int64_t id;
            time_t generation;
            ASEventPrototype* prototype;
            asIScriptContext* context;
            
            std::chrono::high_resolution_clock::time_point startTime{};
            std::chrono::microseconds totalRuntime{};
            std::optional<ScriptResult> result;
            int suspendCounts{0};
            double countDown{0.0};
    };


    extern std::unordered_map<std::string, ASEventPrototype*> ASEventPrototypes;

}
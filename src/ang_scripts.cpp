#include "dbat/ang_scripts.h"
#include "dbat/utils.h"

namespace ang {
    asIScriptEngine* engine;
    CContextMgr* contextMgr;

    static void MessageCallback(const asSMessageInfo *msg, void *param) {
        const char *type = "ERR ";
        if (msg->type == asMSGTYPE_WARNING)
            type = "WARN";
        else if (msg->type == asMSGTYPE_INFORMATION)
            type = "INFO";
        basic_mud_log("%s (%d, %d) : %s : %s\n", msg->section, msg->row, msg->col, type, msg->message);
    }

    static void registerEnums() {
        registerEnumClass<RaceID>("RaceID");
        registerEnumClass<SenseiID>("SenseiID");
        registerEnumClass<FormID>("FormID");
        registerEnumClass<SkillID>("SkillID");
        registerEnumClass<CharAttribute>("CharAttribute");
        registerEnumClass<CharTrain>("CharTrain");
        registerEnumClass<CharAppearance>("CharAppearance");
        registerEnumClass<CharAlign>("CharAlign");
        registerEnumClass<CharMoney>("CharMoney");
        registerEnumClass<CharVital>("CharVital");
        registerEnumClass<CharNum>("CharNum");
        registerEnumClass<CharStat>("CharStat");
        registerEnumClass<CharDim>("CharDim");
        registerEnumClass<ComStat>("ComStat");
        registerEnumClass<AtkTier>("AtkTier");
        registerEnumClass<DamType>("DamType");
    }

    static void registerCharacters() {
        registerThingBase<CharRef>("Character");
    }

    static void registerTypes() {

        registerEnums();

        int r = 0;
        r = engine->RegisterObjectType("Character", sizeof(CharRef), asOBJ_VALUE | asOBJ_APP_CLASS_CDAK);
        assert(r >= 0);
        r = engine->RegisterObjectType("Object", sizeof(ObjRef), asOBJ_VALUE | asOBJ_APP_CLASS_CDAK);
        assert(r >= 0);
        r = engine->RegisterObjectType("Room", sizeof(RoomRef), asOBJ_VALUE | asOBJ_APP_CLASS_CDAK);
        assert(r >= 0);

        registerTrivialConDec<ObjRef>("Object");
        registerTrivialConDec<CharRef>("Character");
        registerTrivialConDec<RoomRef>("Room");

        registerCharacters();

    }

    static void registerStandardLibrary() {
        // Register addons
        RegisterStdString(engine);
        RegisterScriptArray(engine, true);

        RegisterScriptDictionary(engine);

        RegisterScriptMath(engine);
        RegisterScriptMathComplex(engine);

        // Engage Coroutine support.
        contextMgr->RegisterCoRoutineSupport(engine);

    }

    void initAngelScript() {
        engine = asCreateScriptEngine();
        int r = engine->SetMessageCallback(asFUNCTION(MessageCallback), nullptr, asCALL_CDECL);
        if (r < 0) {
            std::cerr << "Failed to set the message callback." << std::endl;
            return;
        }

        contextMgr = new CContextMgr();

        // do engine setup here?
        registerStandardLibrary();
        registerTypes();

    }

    ASEventPrototype::ASEventPrototype(const std::string &id) : id(id) {}

    ASEventPrototype::~ASEventPrototype() {
        if(module) {
            module->Discard();
        }
    }

    const std::string& ASEventPrototype::getId() const {
        return id;
    }

    asIScriptModule* ASEventPrototype::getModule() {
        if(!module) {
            buildModule();
        }
        return module;
    }

    std::unordered_set<ASEvent*> suspendedContexts;


    // ASPrototype implementation.
    void ASEventPrototype::setCode(const std::vector<std::pair<std::string, std::string>> &code) {
        for(auto &asctx : contexts) {
            asctx->abort();
        }
        this->code = code;
    }

    void ASEventPrototype::buildModule() {
        module = engine->GetModule(id.c_str(), asGM_ALWAYS_CREATE);
        for(auto &pair : code) {
            auto r = module->AddScriptSection(pair.first.c_str(), pair.second.c_str());
            if(r < 0) {
                module->Discard();
                module = nullptr;
                return;
            }
        }
        auto r = module->Build();
        if(r < 0) {
            module->Discard();
            module = nullptr;
            return;
        }
    }

    void ASEventPrototype::registerContext(ASEvent* context) {
        contexts.insert(context);
    }

    void ASEventPrototype::unregisterContext(ASEvent* context) {
        contexts.erase(context);
    }



    // ASContext implementation.
    ASEvent::ASEvent(UID owner, int64_t id, time_t generation, ASEventPrototype* prototype) : owner(owner), id(id), generation(generation), prototype(prototype) {
        prototype->registerContext(this);
    }

    ASEvent::~ASEvent() {
        if(context)
            contextMgr->DoneWithContext(context);
        prototype->unregisterContext(this);
    }

    void ASEvent::reset() {
        if(context) {
            contextMgr->DoneWithContext(context);
            context = nullptr;
        }
        result.reset();
        totalRuntime = std::chrono::microseconds(0);
        countDown = 0.0;
        suspendCounts = 0;
    }

    void ASEvent::prepare() {
        auto func = prototype->getModule()->GetFunctionByDecl("void main(Script @)");
        context = contextMgr->AddContext(engine, func, false);
        context->SetLineCallback(asMETHOD(ASEvent, lineCallback), this, asCALL_THISCALL);
    }

    void ASEvent::lineCallback(asIScriptContext* ctx) {
        auto curTime = std::chrono::high_resolution_clock::now();
        // if we have been running for at least 10 ms, suspend the context
        if(std::chrono::duration_cast<std::chrono::milliseconds>(curTime - startTime).count() > 10) {
            suspendCounts++;
            if(suspendCounts >= 10) {
                basic_mud_log("ASContext: %s has been running for too long.", debugName().c_str());
                ctx->Abort();
            } else {
                ctx->Suspend();
            }
        }
    }

    bool ASEvent::isReady() const {
        return context && context->GetState() == asEXECUTION_PREPARED;
    }

    void ASEvent::abort() {
        if(context) {
            context->Abort();
        }
    }

    std::optional<ScriptResult> ASEvent::execute() {
        result.reset();
        if(!context) return {};

        switch(context->GetState()) {
            case asEXECUTION_PREPARED:
            case asEXECUTION_SUSPENDED:
                break;
            default:
                basic_mud_log("ASContext: %s is in an invalid state.", debugName().c_str());
                return {};
                break;
        }
        
        startTime = std::chrono::high_resolution_clock::now();
        auto r = context->Execute();
        auto endTime = std::chrono::high_resolution_clock::now();
        totalRuntime += std::chrono::duration_cast<std::chrono::microseconds>(endTime - startTime);

        bool clear = true;
        switch(r) {
            case asEXECUTION_FINISHED:
                break;
            case asEXECUTION_SUSPENDED:
                clear = false;
                suspendedContexts.insert(this);
                break;
            case asEXECUTION_ABORTED:
                basic_mud_log("ASContext: %s was aborted.", debugName().c_str());
                break;
            case asEXECUTION_EXCEPTION:
                basic_mud_log("ASContext: %s threw an exception.", debugName().c_str());
                break;
            default:
                basic_mud_log("ASContext: %s is in an invalid state.", debugName().c_str());
                break;
        }

        if(clear) {
            auto res = result;
            reset();
            return res;
        }

        return result;
    }

    asIScriptContext* ASEvent::getContext() const {
        return context;
    }
    
    ASEventPrototype* ASEvent::getPrototype() const {
        return prototype;
    }

    std::string ASEvent::debugName() const {
        return fmt::format("#ASE:{}:{} [{}]", id, generation, prototype->getId());
    }


    std::unordered_map<std::string, ASEventPrototype*> ASEventPrototypes;

}

InstanceMap<ang::ASEvent> ang::ASEvent::instances;
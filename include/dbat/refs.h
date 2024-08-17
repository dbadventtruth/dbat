#pragma once
#include "structs.h"
#include "scriptarray/scriptarray.h"

namespace ref {

    template<typename T>
    bool isValid(const T& ref) {
        return ref.get() != nullptr;
    }

    // Unit Data Section.
    template<typename T>
    std::string getName(const T &ref) {
        if(auto u = ref.get(); u) {
            return u->getName();
        } else {
            return "";
        }
    }

    template<typename T>
    std::string getShortDescription(const T &ref) {
        if(auto u = ref.get(); u) {
            return u->getShortDescription();
        } else {
            return "";
        }
    }

    template<typename T>
    std::string getRoomDescription(const T &ref) {
        if(auto u = ref.get(); u) {
            return u->getRoomDescription();
        } else {
            return "";
        }
    }

    template<typename T>
    std::string getLookDescription(const T &ref) {
        if(auto u = ref.get(); u) {
            return u->getLookDescription();
        } else {
            return "";
        }
    }

    template<typename T>
    void setVarCharacter(const T &ref, const std::string &name, CharRef character) {
        if(auto u = ref.get(); u) {
            auto &vars = u->variables[name];
            vars.setCharacter(name, character);
        }
    }

    template<typename T>
    CharRef getVarCharacter(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                return find->second.getCharacter(name);
            }
        }
        return CharRef();
    }

    template<typename T>
    void clearVarCharacter(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                find->second.clearCharacter(name);
            }
        }
    }

    template<typename T>
    void setVarObject(const T &ref, const std::string &name, ObjRef object) {
        if(auto u = ref.get(); u) {
            auto &vars = u->variables[name];
            vars.setObject(name, object);
        }
    }

    template<typename T>
    ObjRef getVarObject(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                return find->second.getObject(name);
            }
        }
        return ObjRef();
    }

    template<typename T>
    void clearVarObject(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                find->second.clearObject(name);
            }
        }
    }

    template<typename T>
    void setVarRoom(const T &ref, const std::string &name, RoomRef room) {
        if(auto u = ref.get(); u) {
            auto &vars = u->variables[name];
            vars.setRoom(name, room);
        }
    }

    template<typename T>
    RoomRef getVarRoom(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                return find->second.getRoom(name);
            }
        }
        return RoomRef();
    }

    template<typename T>
    void clearVarRoom(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                find->second.clearRoom(name);
            }
        }
    }

    template<typename T>
    void setVarString(const T &ref, const std::string &name, const std::string &value) {
        if(auto u = ref.get(); u) {
            auto &vars = u->variables[name];
            vars.setString(name, value);
        }
    }

    template<typename T>
    std::string getVarString(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                return find->second.getString(name);
            }
        }
        return "";
    }

    template<typename T>
    void clearVarString(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                find->second.clearString(name);
            }
        }
    }

    template<typename T>
    void setVarInt(const T &ref, const std::string &name, int64_t value) {
        if(auto u = ref.get(); u) {
            auto &vars = u->variables[name];
            vars.setInt(name, value);
        }
    }

    template<typename T>
    int64_t getVarInt(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                return find->second.getInt(name);
            }
        }
        return 0;
    }

    template<typename T>
    void clearVarInt(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                find->second.clearInt(name);
            }
        }
    }

    template<typename T>
    void setVarDouble(const T &ref, const std::string &name, double value) {
        if(auto u = ref.get(); u) {
            auto &vars = u->variables[name];
            vars.setDouble(name, value);
        }
    }

    template<typename T>
    double getVarDouble(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                return find->second.getDouble(name);
            }
        }
        return 0.0;
    }

    template<typename T>
    void clearVarDouble(const T &ref, const std::string &name) {
        if(auto u = ref.get(); u) {
            if(auto find = u->variables.find(name); find != u->variables.end()) {
                find->second.clearDouble(name);
            }
        }
    }

    template<typename T>
    CScriptArray* RefToArray(const std::string& name, const std::vector<T>& refs) {
        // Create the array in AngelScript of type 'array<T>'
        auto typeName = "array<" + name + ">@";
        asITypeInfo* arrayType = ang::engine->GetTypeInfoByDecl(typeName.c_str());
        CScriptArray* asArray = CScriptArray::Create(arrayType, refs.size());

        // Populate the AngelScript array with ObjRef (which is registered as Object in AS)
        for (size_t i = 0; i < refs.size(); ++i) {
            asArray->SetValue(i, refs.at(i)); // Directly set the ObjRef (Object) into the array
        }

        // Return the populated array
        return asArray;
    }

    template<typename T>
    CScriptArray* getContents(const T &ref) {
        if (auto u = ref.get(); u) {
            return RefToArray("Object", u->getContents());
        }
        return nullptr;
    }

    template<typename T>
    ObjRef findObjectVnum(const T &ref, vnum vn) {
        if(auto u = ref.get(); u) {
            return u->findObjectVnum(vn);
        }
        return ObjRef();
    }

    // Begin thing_data section.
    template<typename T>
    RoomRef getRoom(const T &ref) {
        if(auto t = ref.get(); t) {
            return t->getRoom();
        } else {
            return RoomRef();
        }
    }

    template<typename T>
    int getRoomVnum(const T &ref) {
        if(auto t = ref.get(); t) {
            return t->getRoomVnum();
        }
        return 0;
    }

    template<typename T>
    CScriptArray* getLocationObjects(const T &ref) {
        if(auto t = ref.get(); t) {
            if(auto r = t.getRoom(); r) {
                return getContents<T>(ref);
            }
        }
        return nullptr;
    }

    template<typename T>
    CScriptArray* getLocationPeople(const T &ref) {
        if(auto t = ref.get(); t) {
            if(auto r = t.getRoom(); r) {
                return RefToArray<CharRef>("Character", r->getPeople());
            }
        }
        return nullptr;
    }
}

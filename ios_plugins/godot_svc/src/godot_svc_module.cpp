/*************************************************************************/
/*  godot_svc_module.cpp                                                 */
/*************************************************************************/
#include "godot_svc_module.h"
#include "core/version.h"
#if VERSION_MAJOR == 4
#include "core/config/engine.h"
#else
#include "core/engine.h"
#endif
#include "godot_svc.h"

GodotSvc *godot_svc;
void register_godot_svc_plugin() {
	godot_svc = memnew(GodotSvc);
	Engine::get_singleton()->add_singleton(Engine::Singleton("GodotSvc", godot_svc));
}

void unregister_godot_svc_plugin() {
	if (godot_svc) {
		memdelete(godot_svc);
	}
}
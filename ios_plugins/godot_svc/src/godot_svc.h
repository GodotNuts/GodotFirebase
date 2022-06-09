/*************************************************************************/
/*  godot_svc.h                                                          */
/*************************************************************************/

#ifndef GODOTSVC_H
#define GODOTSVC_H

#include "core/version.h"
#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
#else
#include "core/object.h"
#endif

class GodotSvc : public Object {

	GDCLASS(GodotSvc, Object);

	static GodotSvc *instance;
	static void _bind_methods();

public:
	static GodotSvc *get_singleton();
    void popup(String url);
    void close();
	GodotSvc();
	~GodotSvc();
};

#endif

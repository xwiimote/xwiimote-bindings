%module xwiimote

/*
  Each time xwiimote.h is updated, you should update this file, at least the information below to tell you integrated the last changes.

  From commit 64a7904283858a9987131965f14398ad8391f2a4
  a9d7f2367cb78bd85e5227abb5077caa5338606e lib/xwiimote.h
*/

%include "exception.i"

/*
  Tell to Swig that some parameters must be considered as output parameters.
  This is done when there is more than 1 output parameter, and then, not possible to rewrite it in C.
*/
%apply int          *OUTPUT { int* x, int* y, int* z, int* factor };
%apply unsigned int *OUTPUT { unsigned int* code, unsigned int* state };
%apply unsigned int *OUTPUT { long int* tv_sec, long int* tv_usec };

%{
#include <xwiimote.h>

/*
  exceptions are handle via a global variable as written in the documentation to make use of %except
  this require the following help functions and macro.
*/

static int  xwii_exception_status = 0;   /* 1 = exception set   */
static int  xwii_exception_errno  = 0;   /* errno               */
static int  xwii_exception_type   = 0;   /* swig exception type */
static char xwii_exception_message[256]; /* message             */

void xwii_throw_exception(char *msg, int error_number, int type)
{
	xwii_exception_status = 1;
	xwii_exception_errno  = error_number;
	xwii_exception_type   = type;
	snprintf(xwii_exception_message, sizeof(xwii_exception_message), "%s (%i)", msg, error_number);
}

void xwii_clear_exception(void)
{
	xwii_exception_status = 0;
}

char *xwii_check_exception(void)
{
	if (xwii_exception_status != 0) {
		return xwii_exception_message;
	} else {
		return NULL;
	}
}

int xwii_get_exception_errno(void)
{
	return xwii_exception_errno;
}

int xwii_get_exception_type(void)
{
	return xwii_exception_type;
}

%}

/*
XWIIEXCEPTION_BASIC for simple exceptions
XWIIEXCEPTION_ERRNO which must use the error number as ERRNO
*/

%define XWIIEXCEPTION_BASIC(func)
%exception func {
  char* excep;
  xwii_clear_exception();
  $action
  excep = xwii_check_exception();
  if(excep != NULL)
  {
	  SWIG_exception(xwii_get_exception_type(), excep);
  }
}
%enddef

#ifdef SWIGPYTHON
%define XWIIEXCEPTION_ERRNO(func)
%exception func {
  char* excep;
  xwii_clear_exception();
  $action
  excep = xwii_check_exception();
  if(excep != NULL)
  {
	  errno = -xwii_get_exception_errno();
	  switch(xwii_get_exception_type())
	  {
	  case SWIG_IOError:
		  PyErr_SetFromErrno(PyExc_IOError);
		  break;
	  case SWIG_SystemError:
		  PyErr_SetFromErrno(PyExc_SystemError);
		  break;
	  case SWIG_ValueError:
		  PyErr_SetFromErrno(PyExc_ValueError);
		  break;
	  }
	  return NULL; /* this return must not be remove, otherwise python exception doesn't work ;
			  contrary to SWIG_exception which must not have a return after */
  }
}
%enddef
#else
%define XWIIEXCEPTION_ERRNO(func)
%exception func {
  char* excep;
  xwii_clear_exception();
  $action
  excep = xwii_check_exception();
  if(excep != NULL)
  {
	  /* works for        : perl
	     doesn't work for : python (doesn't fill the python errno) */
	  errno = -xwii_get_exception_errno();
	  SWIG_exception(xwii_get_exception_type(), excep);
  }
}
%enddef
#endif

/*
  functions are rewritten to help swig to understand :
  - output parameters
  - exceptions
  - hide uint8_t, typeval, union
  - remove unrequired parameters (sizeof)
  - classes
  - memory to free
*/

/***** monitor class *****/
/* renaming
  function are renamed because swig already uses the <class_name>_<function> for internal use,
  and the xwiimote api uses structures as prefix of functions
*/
%rename(monitor) xwii_monitor;
%rename(get_fd)  xm_get_fd;
%rename(poll)    xm_poll;

/* memory to be freed */
%newobject xm_poll;

/* exceptions */
XWIIEXCEPTION_BASIC(xwii_monitor)
XWIIEXCEPTION_BASIC(xm_get_fd)

struct xwii_monitor {
%extend {
	xwii_monitor(bool poll, bool direct)
	{
		struct xwii_monitor* mon;
		mon = xwii_monitor_new(poll, direct);
		if(mon == NULL)
		{
			xwii_throw_exception("xwii_monitor_new() failed", -1, SWIG_SystemError);
		}
		return mon;
	}

	~xwii_monitor()
	{
		xwii_monitor_unref($self);
	}

	int xm_get_fd(bool blocking)
	{
		int fd;
		fd = xwii_monitor_get_fd($self, blocking);
		if(fd == -1)
		{
			xwii_throw_exception("xwii_monitor_get_fd() failed", -1, SWIG_SystemError);
		}
		return fd;
	}
	
	char* xm_poll()
	{
		return xwii_monitor_poll($self);
	}
}
};

/***** event class *****/
/* renaming */
%rename(event)    xwii_event;
%rename(get_abs)  xe_get_abs;
%rename(set_abs)  xe_set_abs;
%rename(get_key)  xe_get_key;
%rename(set_key)  xe_set_key;
%rename(get_time) xe_get_time;
%rename(set_time) xe_set_time;
%rename(ir_is_valid) xe_ir_is_valid;

/* exceptions */
XWIIEXCEPTION_ERRNO(xe_get_abs)
XWIIEXCEPTION_ERRNO(xe_set_abs)
XWIIEXCEPTION_ERRNO(xe_ir_is_valid)

struct xwii_event {
	unsigned int type;
%extend {
	void xe_get_abs(int n, int* x, int *y, int* z)
	{
		if(n<0 || n>=XWII_ABS_NUM)
		{
			xwii_throw_exception("xwii_event_get_abs failed", -EINVAL, SWIG_ValueError);
			return;
		}
		*x = (int) $self->v.abs[n].x;
		*y = (int) $self->v.abs[n].y;
		*z = (int) $self->v.abs[n].z;
	}
	
	void xe_set_abs(int n, int x, int y, int z)
	{
		if(n<0 || n>=XWII_ABS_NUM)
		{
			xwii_throw_exception("xwii_event_set_abs failed", -EINVAL, SWIG_ValueError);
			return;
		}
		$self->v.abs[n].x = (int32_t) x;
		$self->v.abs[n].y = (int32_t) y;
		$self->v.abs[n].z = (int32_t) z;
	}
	
	void xe_get_key(unsigned int* code, unsigned int* state)
	{
		*code  = $self->v.key.code;
		*state = $self->v.key.state;
	}
	
	void xe_set_key(unsigned int code, unsigned int state)
	{
		$self->v.key.code  = code;
		$self->v.key.state = state;
	}
	
	void xe_get_time(long int* tv_sec, long int* tv_usec)
	{
		*tv_sec  = $self->time.tv_sec;
		*tv_usec = $self->time.tv_usec;
	}

	void xe_set_time(long int tv_sec, long int tv_usec)
	{
		$self->time.tv_sec  = tv_sec;
		$self->time.tv_usec = tv_usec;
	}

	bool xe_ir_is_valid(int n)
	{
		if(n<0 || n>=XWII_ABS_NUM) /* avoid a segfault */
		{
			xwii_throw_exception("xwii_event_ir_is_valid failed", -EINVAL, SWIG_ValueError);
			return false;
		}
		return xwii_event_ir_is_valid($self->v.abs+n);
	}
}
};

/***** iface class *****/
/* renaming */
%rename(iface)         	      xwii_iface;
%rename(open)          	      xif_open;
%rename(close)         	      xif_close;
%rename(opened)        	      xif_opened;
%rename(get_syspath)   	      xif_get_syspath;
%rename(get_fd)        	      xif_get_fd;
%rename(available)     	      xif_available;
%rename(dispatch)      	      xif_dispatch;
%rename(rumble)        	      xif_rumble;
%rename(get_led)       	      xif_get_led;
%rename(set_led)       	      xif_set_led;
%rename(get_battery)   	      xif_get_battery;
%rename(get_devtype)   	      xif_get_devtype;
%rename(get_extension) 	      xif_get_extension;
%rename(set_mp_normalization) xif_set_mp_normalization;
%rename(get_mp_normalization) xif_get_mp_normalization;
%rename(get_name)             xif_get_name;

/* memory to be freed */
%newobject xif_get_devtype;
%newobject xif_get_extension;

/* exceptions */
XWIIEXCEPTION_ERRNO(xwii_iface)
XWIIEXCEPTION_ERRNO(xif_open)
XWIIEXCEPTION_BASIC(xif_get_syspath)
XWIIEXCEPTION_ERRNO(xif_dispatch)
XWIIEXCEPTION_ERRNO(xif_rumble)
XWIIEXCEPTION_ERRNO(xif_get_led)
XWIIEXCEPTION_ERRNO(xif_set_led)
XWIIEXCEPTION_ERRNO(xif_get_battery)
XWIIEXCEPTION_ERRNO(xif_get_devtype)
XWIIEXCEPTION_ERRNO(xif_get_extensiond)

struct xwii_iface {
%extend {
	xwii_iface(const char *syspath)
	{
		struct xwii_iface* dev;
		int ret;
		
		if((ret=xwii_iface_new(&dev, syspath)) != 0) {
			xwii_throw_exception("xwii_iface_new() failed", ret, SWIG_IOError);
			return NULL;
		}
		if((ret=xwii_iface_watch(dev, true)) != 0)
		{
			xwii_throw_exception("xwii_iface_watch() failed", ret, SWIG_IOError);
			return NULL;
		}
		return dev;
	}

	~xwii_iface()
	{
		xwii_iface_unref($self);
	}
	
	void xif_open(unsigned int ifaces)
	{
		int ret;
		if((ret=xwii_iface_open($self, ifaces)) != 0)
		{
			xwii_throw_exception("xwii_iface_open failed", ret, SWIG_IOError);
		}
	}
	
	void xif_close(unsigned int ifaces)
	{
		xwii_iface_close($self, ifaces);
	}
	
	unsigned int xif_opened()
	{
		return xwii_iface_opened($self);
	}
	
	const char* xif_get_syspath()
	{
		const char* syspath;
		if((syspath = xwii_iface_get_syspath($self)) == NULL)
		{
			xwii_throw_exception("xwii_iface_get_syspath failed", -1, SWIG_IOError);
		}
		return syspath;
	}
	
	int xif_get_fd()
	{
		return xwii_iface_get_fd($self);
	}

	unsigned int xif_available()
	{
		return xwii_iface_available($self);
	}
	
	void xif_dispatch(struct xwii_event *ev)
	{
		int ret;
		if((ret=xwii_iface_dispatch($self, ev, sizeof(struct xwii_event))) != 0)
		{
			xwii_throw_exception("xwii_iface_dispatch failed", ret, SWIG_IOError);
		}
	}
	
	void xif_rumble(bool on)
	{
		int ret;
		if((ret=xwii_iface_rumble($self, on)) != 0)
		{
			xwii_throw_exception("xwii_iface_rumble failed", ret, SWIG_IOError);
		}
	}
	
	bool xif_get_led(unsigned int led)
	{
		bool state;
		int ret;
		if(led<XWII_LED1 || led>XWII_LED4)
		{
			xwii_throw_exception("xwii_iface_get_led failed", -EINVAL, SWIG_ValueError);
			return false;
		}
		if((ret=xwii_iface_get_led($self, led, &state)) != 0)
		{
			xwii_throw_exception("xwii_iface_get_led failed", ret, SWIG_IOError);
			return false;
		}
		return state;
	}
	
	void xif_set_led(unsigned int led, bool state)
	{
		int ret;
		if(led<XWII_LED1 || led>XWII_LED4)
		{
			xwii_throw_exception("xwii_iface_get_sed failed", -EINVAL, SWIG_ValueError);
			return;
		}
		if((ret=xwii_iface_set_led($self, led, state)) != 0)
		{
			xwii_throw_exception("xwii_iface_set_led failed", ret, SWIG_IOError);
		}
	}
	
	int xif_get_battery()
	{
		uint8_t capacity;
		int ret;
		if((ret=xwii_iface_get_battery($self, &capacity)) != 0)
		{
			xwii_throw_exception("xwii_iface_get_battery failed", ret, SWIG_IOError);
			return 0;
		}
		return ((int) capacity);
	}
	
	char* xif_get_devtype()
	{
		char* devtype;
		int ret;
		if((ret=xwii_iface_get_devtype($self, &devtype)) != 0)
		{
			xwii_throw_exception("xwii_iface_get_devtype failed", ret, SWIG_IOError);
			return NULL;
		}
		return devtype;
	}
	
	char* xif_get_extension()
	{
		char* extension;
		int ret;
		if((ret=xwii_iface_get_extension($self, &extension)) != 0)
		{
			xwii_throw_exception("xwii_iface_get_extension failed", ret, SWIG_IOError);
			return NULL;
		}
		return extension;
	}
	
	void xif_set_mp_normalization(int x, int y, int z, int factor)
	{
		int32_t _x, _y, _z, _factor;
		_x = (int32_t) x;
		_y = (int32_t) y;
		_z = (int32_t) z;
		_factor = (int32_t) factor;
		xwii_iface_set_mp_normalization($self, _x, _y, _z, _factor);
	}

	void xif_get_mp_normalization(int *x, int *y, int *z, int *factor)
	{
		int32_t _x, _y, _z, _factor;
		xwii_iface_get_mp_normalization($self, &_x, &_y, &_z, &_factor);   
		*x = (int) _x;
		*y = (int) _y;
		*z = (int) _z;
		*factor = (int) _factor;
	}

	static const char* xif_get_name(unsigned int iface)
	{
		return xwii_get_iface_name(iface);
	}
}
};

/* ************** */

/***** constants *****/

%ignore XWII__NAME;
%rename(NAME_CORE)  	  	 XWII_NAME_CORE;
%rename(NAME_ACCEL) 	  	 XWII_NAME_ACCEL;
%rename(NAME_IR)    	  	 XWII_NAME_IR;
%rename(NAME_MOTION_PLUS) 	 XWII_NAME_MOTION_PLUS;
%rename(NAME_NUNCHUK)     	 XWII_NAME_NUNCHUK;
%rename(NAME_CLASSIC_CONTROLLER) XWII_NAME_CLASSIC_CONTROLLER;
%rename(NAME_BALANCE_BOARD)      XWII_NAME_BALANCE_BOARD;
%rename(NAME_PRO_CONTROLLER)     XWII_NAME_PRO_CONTROLLER;
%rename(NAME_DRUMS)  		 XWII_NAME_DRUMS;
%rename(NAME_GUITAR) 		 XWII_NAME_GUITAR;

#define XWII__NAME			"Nintendo Wii Remote"
#define XWII_NAME_CORE			XWII__NAME
#define XWII_NAME_ACCEL			XWII__NAME " Accelerometer"
#define XWII_NAME_IR			XWII__NAME " IR"
#define XWII_NAME_MOTION_PLUS		XWII__NAME " Motion Plus"
#define XWII_NAME_NUNCHUK		XWII__NAME " Nunchuk"
#define XWII_NAME_CLASSIC_CONTROLLER	XWII__NAME " Classic Controller"
#define XWII_NAME_BALANCE_BOARD		XWII__NAME " Balance Board"
#define XWII_NAME_PRO_CONTROLLER	XWII__NAME " Pro Controller"
#define XWII_NAME_DRUMS			XWII__NAME " Drums"
#define XWII_NAME_GUITAR		XWII__NAME " Guitar"

%rename(EVENT_KEY)   	     	       XWII_EVENT_KEY;
%rename(EVENT_ACCEL) 	     	       XWII_EVENT_ACCEL;
%rename(EVENT_IR)    	     	       XWII_EVENT_IR;
%rename(EVENT_BALANCE_BOARD) 	       XWII_EVENT_BALANCE_BOARD;
%rename(EVENT_BALANCE_BOARD_KEY)       XWII_EVENT_BALANCE_BOARD_KEY;
%rename(EVENT_MOTION_PLUS)   	       XWII_EVENT_MOTION_PLUS;
%rename(EVENT_PRO_CONTROLLER_KEY)      XWII_EVENT_PRO_CONTROLLER_KEY;
%rename(EVENT_PRO_CONTROLLER_MOVE)     XWII_EVENT_PRO_CONTROLLER_MOVE;
%rename(EVENT_WATCH)                   XWII_EVENT_WATCH;
%rename(EVENT_CLASSIC_CONTROLLER_KEY)  XWII_EVENT_CLASSIC_CONTROLLER_KEY;
%rename(EVENT_CLASSIC_CONTROLLER_MOVE) XWII_EVENT_CLASSIC_CONTROLLER_MOVE;
%rename(EVENT_NUNCHUK_KEY)  	       XWII_EVENT_NUNCHUK_KEY;
%rename(EVENT_NUNCHUK_MOVE) 	       XWII_EVENT_NUNCHUK_MOVE;
%rename(EVENT_DRUMS_KEY)    	       XWII_EVENT_DRUMS_KEY;
%rename(EVENT_DRUMS_MOVE)   	       XWII_EVENT_DRUMS_MOVE;
%rename(EVENT_GUITAR_KEY)   	       XWII_EVENT_GUITAR_KEY;
%rename(EVENT_GUITAR_MOVE)  	       XWII_EVENT_GUITAR_MOVE;
%rename(EVENT_GONE) 	    	       XWII_EVENT_GONE;
%rename(EVENT_NUM)  	    	       XWII_EVENT_NUM;

enum xwii_event_types {
	XWII_EVENT_KEY,
	XWII_EVENT_ACCEL,
	XWII_EVENT_IR,
	XWII_EVENT_BALANCE_BOARD,
        XWII_EVENT_BALANCE_BOARD_KEY,
	XWII_EVENT_MOTION_PLUS,
	XWII_EVENT_PRO_CONTROLLER_KEY,
	XWII_EVENT_PRO_CONTROLLER_MOVE,
	XWII_EVENT_WATCH,
	XWII_EVENT_CLASSIC_CONTROLLER_KEY,
	XWII_EVENT_CLASSIC_CONTROLLER_MOVE,
	XWII_EVENT_NUNCHUK_KEY,
	XWII_EVENT_NUNCHUK_MOVE,
	XWII_EVENT_DRUMS_KEY,
	XWII_EVENT_DRUMS_MOVE,
	XWII_EVENT_GUITAR_KEY,
	XWII_EVENT_GUITAR_MOVE,
	XWII_EVENT_GONE,
	XWII_EVENT_NUM,
};

%rename(KEY_LEFT)  	    XWII_KEY_LEFT;
%rename(KEY_RIGHT) 	    XWII_KEY_RIGHT;
%rename(KEY_UP)    	    XWII_KEY_UP;
%rename(KEY_DOWN)  	    XWII_KEY_DOWN;
%rename(KEY_A)     	    XWII_KEY_A;
%rename(KEY_B)     	    XWII_KEY_B;
%rename(KEY_PLUS)  	    XWII_KEY_PLUS;
%rename(KEY_MINUS) 	    XWII_KEY_MINUS;
%rename(KEY_HOME)  	    XWII_KEY_HOME;
%rename(KEY_ONE)   	    XWII_KEY_ONE;
%rename(KEY_TWO)   	    XWII_KEY_TWO;
%rename(KEY_X) 		    XWII_KEY_X;
%rename(KEY_Y) 		    XWII_KEY_Y;
%rename(KEY_TL)    	    XWII_KEY_TL;
%rename(KEY_TR)    	    XWII_KEY_TR;
%rename(KEY_ZL) 	    XWII_KEY_ZL;
%rename(KEY_ZR) 	    XWII_KEY_ZR;
%rename(KEY_THUMBL) 	    XWII_KEY_THUMBL;
%rename(KEY_THUMBR) 	    XWII_KEY_THUMBR;
%rename(KEY_C)      	    XWII_KEY_C;
%rename(KEY_Z)      	    XWII_KEY_Z;
%rename(KEY_STRUM_BAR_UP)   XWII_KEY_STRUM_BAR_UP;
%rename(KEY_STRUM_BAR_DOWN) XWII_KEY_STRUM_BAR_DOWN;
%rename(KEY_FRET_FAR_UP)    XWII_KEY_FRET_FAR_UP;
%rename(KEY_FRET_UP)  	    XWII_KEY_FRET_UP;
%rename(KEY_FRET_MID) 	    XWII_KEY_FRET_MID;
%rename(KEY_FRET_LOW) 	    XWII_KEY_FRET_LOW;
%rename(KEY_FRET_FAR_LOW)   XWII_KEY_FRET_FAR_LOW;
%rename(KEY_NUM)            XWII_KEY_NUM;

enum xwii_event_keys {
	XWII_KEY_LEFT,
	XWII_KEY_RIGHT,
	XWII_KEY_UP,
	XWII_KEY_DOWN,
	XWII_KEY_A,
	XWII_KEY_B,
	XWII_KEY_PLUS,
	XWII_KEY_MINUS,
	XWII_KEY_HOME,
	XWII_KEY_ONE,
	XWII_KEY_TWO,
	XWII_KEY_X,
	XWII_KEY_Y,
	XWII_KEY_TL,
	XWII_KEY_TR,
	XWII_KEY_ZL,
	XWII_KEY_ZR,
	XWII_KEY_THUMBL,
	XWII_KEY_THUMBR,
	XWII_KEY_C,
	XWII_KEY_Z,
	XWII_KEY_STRUM_BAR_UP,
	XWII_KEY_STRUM_BAR_DOWN,
	XWII_KEY_FRET_FAR_UP,
	XWII_KEY_FRET_UP,
	XWII_KEY_FRET_MID,
	XWII_KEY_FRET_LOW,
	XWII_KEY_FRET_FAR_LOW,
	XWII_KEY_NUM,
};

%rename(DRUMS_ABS_PAD)           XWII_DRUMS_ABS_PAD;
%rename(DRUMS_ABS_CYMBAL_LEFT)   XWII_DRUMS_ABS_CYMBAL_LEFT;
%rename(DRUMS_ABS_CYMBAL_RIGHT)  XWII_DRUMS_ABS_CYMBAL_RIGHT;
%rename(DRUMS_ABS_TOM_LEFT)      XWII_DRUMS_ABS_TOM_LEFT;
%rename(DRUMS_ABS_TOM_RIGHT)     XWII_DRUMS_ABS_TOM_RIGHT;
%rename(DRUMS_ABS_TOM_FAR_RIGHT) XWII_DRUMS_ABS_TOM_FAR_RIGHT;
%rename(DRUMS_ABS_BASS)   	 XWII_DRUMS_ABS_BASS;
%rename(DRUMS_ABS_HI_HAT) 	 XWII_DRUMS_ABS_HI_HAT;
%rename(DRUMS_ABS_NUM)    	 XWII_DRUMS_ABS_NUM;

enum xwii_drums_abs {
	XWII_DRUMS_ABS_PAD,
	XWII_DRUMS_ABS_CYMBAL_LEFT,
	XWII_DRUMS_ABS_CYMBAL_RIGHT,
	XWII_DRUMS_ABS_TOM_LEFT,
	XWII_DRUMS_ABS_TOM_RIGHT,
	XWII_DRUMS_ABS_TOM_FAR_RIGHT,
	XWII_DRUMS_ABS_BASS,
	XWII_DRUMS_ABS_HI_HAT,
	XWII_DRUMS_ABS_NUM,
};

%rename(IFACE_CORE)  	   	  XWII_IFACE_CORE;
%rename(IFACE_ACCEL) 	   	  XWII_IFACE_ACCEL;
%rename(IFACE_IR)    	   	  XWII_IFACE_IR;
%rename(IFACE_MOTION_PLUS) 	  XWII_IFACE_MOTION_PLUS;
%rename(IFACE_NUNCHUK)     	  XWII_IFACE_NUNCHUK;
%rename(IFACE_CLASSIC_CONTROLLER) XWII_IFACE_CLASSIC_CONTROLLER;
%rename(IFACE_BALANCE_BOARD)  	  XWII_IFACE_BALANCE_BOARD;
%rename(IFACE_PRO_CONTROLLER) 	  XWII_IFACE_PRO_CONTROLLER;
%rename(IFACE_DRUMS)          	  XWII_IFACE_DRUMS;
%rename(IFACE_GUITAR)         	  XWII_IFACE_GUITAR;
%rename(IFACE_ALL)            	  XWII_IFACE_ALL;
%rename(IFACE_WRITABLE)       	  XWII_IFACE_WRITABLE;

enum xwii_iface_type {
	XWII_IFACE_CORE			= 0x000001,
	XWII_IFACE_ACCEL		= 0x000002,
	XWII_IFACE_IR			= 0x000004,
	XWII_IFACE_MOTION_PLUS		= 0x000100,
	XWII_IFACE_NUNCHUK		= 0x000200,
	XWII_IFACE_CLASSIC_CONTROLLER	= 0x000400,
	XWII_IFACE_BALANCE_BOARD	= 0x000800,
	XWII_IFACE_PRO_CONTROLLER	= 0x001000,
	XWII_IFACE_DRUMS		= 0x002000,
	XWII_IFACE_GUITAR		= 0x004000,
	XWII_IFACE_ALL			= XWII_IFACE_CORE |
					  XWII_IFACE_ACCEL |
					  XWII_IFACE_IR |
					  XWII_IFACE_MOTION_PLUS |
					  XWII_IFACE_NUNCHUK |
					  XWII_IFACE_CLASSIC_CONTROLLER |
					  XWII_IFACE_BALANCE_BOARD |
					  XWII_IFACE_PRO_CONTROLLER |
					  XWII_IFACE_DRUMS |
					  XWII_IFACE_GUITAR,
	XWII_IFACE_WRITABLE		= 0x010000,
};

%rename(LED1) XWII_LED1;
%rename(LED2) XWII_LED2;
%rename(LED3) XWII_LED3;
%rename(LED4) XWII_LED4;

enum xwii_led {
	XWII_LED1 = 1,
	XWII_LED2 = 2,
	XWII_LED3 = 3,
	XWII_LED4 = 4,
};

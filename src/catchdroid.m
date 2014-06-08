#include <jni.h>
#include <errno.h>

#include <EGL/egl.h>
#include <GLES/gl.h>

#include <android/sensor.h>
#include <android/log.h>
#include "android_native_app_glue.h"

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

#include <Foundation/NSObject.h>

#import "Texture.h"

/**
 * Our saved state data.
 */
struct saved_state {
    float angle;
    int32_t x;
    int32_t y;
};

/**
 * Shared state for our app.
 */
@interface Engine : NSObject
{
    @public
    struct android_app* app;

    ASensorManager* sensorManager;
    const ASensor* accelerometerSensor;
    ASensorEventQueue* sensorEventQueue;

    int animating;
    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    int32_t width;
    int32_t height;
    struct saved_state state;

    @private
    Texture * logo;
}
-(int)setupDisplay;
@end

@implementation Engine
/**
 * Initialize an EGL context for the current display.
 */
-(int)setupDisplay
{
    // initialize OpenGL ES and EGL

    /*
     * Here specify the attributes of the desired configuration.
     * Below, we select an EGLConfig with at least 8 bits per color
     * component compatible with on-screen windows
     */
    const EGLint attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_NONE
    };
    EGLint w, h, dummy, format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    eglInitialize(display, 0, 0);

    /* Here, the application chooses the configuration it desires. In this
     * sample, we have a very simplified selection process, where we pick
     * the first EGLConfig that matches our criteria */
    eglChooseConfig(display, attribs, &config, 1, &numConfigs);

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);

    ANativeWindow_setBuffersGeometry(self->app->window, 0, 0, format);

    surface = eglCreateWindowSurface(display, config, self->app->window, NULL);
    context = eglCreateContext(display, config, NULL, NULL);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
        LOGW("Unable to eglMakeCurrent");
        return -1;
    }

    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);

    self->display = display;
    self->context = context;
    self->surface = surface;
    self->width = w;
    self->height = h;
    self->state.angle = 0;

    // Initialize GL state.
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
    glEnable(GL_CULL_FACE);
    glShadeModel(GL_SMOOTH);
    glDisable(GL_DEPTH_TEST);

    logo = [Texture textureWithPath: @"logo.png"];
    [logo retain];

    return 0;
}

/**
 * Just the current frame in the display.
 */
-(void)drawFrame
{
    if (self->display == NULL) {
        // No display.
        return;
    }

    // Just fill the screen with a color.
    glClearColor(
        ((float)self->state.x)/self->width,
        self->state.angle,
        ((float)self->state.y)/self->height,
        1);
    glClear(GL_COLOR_BUFFER_BIT);

    ////////////////////////

    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glBindTexture(GL_TEXTURE_2D, [logo textureId]);
    GLfloat vertices[] = {
      0, 0, 0,
      1, 0, 0,
      1, 1, 0,

      1, 1, 0,
      0, 1, 0,
      0, 0, 0
    };
    GLfloat textures[] = {
      0, 1,
      1, 1,
      1, 0,

      1, 0,
      0, 0,
      0, 1
    };
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, textures);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    //glDrawTexiOES(w/2, h/2, 0, w, h);
    //glDrawTexiOES(0, 0, 0, w, h);

    glDisable(GL_TEXTURE_2D);

    //////////////////

    eglSwapBuffers(self->display, self->surface);
}

/**
 * Tear down the EGL context currently associated with the display.
 */
-(void)terminateDisplay
{
    LOGI("Terminating display");
    [logo release];
    logo = nil;

    if (self->display != EGL_NO_DISPLAY) {
        eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (self->context != EGL_NO_CONTEXT) {
            eglDestroyContext(self->display, self->context);
        }
        if (self->surface != EGL_NO_SURFACE) {
            eglDestroySurface(self->display, self->surface);
        }
        eglTerminate(self->display);
    }
    self->animating = 0;
    self->display = EGL_NO_DISPLAY;
    self->context = EGL_NO_CONTEXT;
    self->surface = EGL_NO_SURFACE;
}
- (void) dealloc
{
   [self terminateDisplay];
   [super dealloc];
}
@end

/**
 * Process the next input event.
 */
static int32_t engine_handle_input(struct android_app* app, AInputEvent* event) {
    Engine * engine = (Engine *)app->userData;
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        engine->animating = 1;
        engine->state.x = AMotionEvent_getX(event, 0);
        engine->state.y = AMotionEvent_getY(event, 0);
        return 1;
    }
    return 0;
}

/**
 * Process the next main command.
 */
static void engine_handle_cmd(struct android_app* app, int32_t cmd) {
    Engine * engine = (Engine *)app->userData;
    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            LOGI("Saving state");
            // The system has asked us to save our current state.  Do so.
            engine->app->savedState = malloc(sizeof(struct saved_state));
            *((struct saved_state*)engine->app->savedState) = engine->state;
            engine->app->savedStateSize = sizeof(struct saved_state);
            break;
        case APP_CMD_INIT_WINDOW:
            LOGI("Initing window");
            // The window is being shown, get it ready.
            if (engine->app->window != NULL) {
                [engine setupDisplay];
                [engine drawFrame];
            }
            break;
        case APP_CMD_TERM_WINDOW:
            LOGI("Terminating window");
            // The window is being hidden or closed, clean it up.
            [engine terminateDisplay];
            break;
        case APP_CMD_GAINED_FOCUS:
            LOGI("Gaining focus");
            // When our app gains focus, we start monitoring the accelerometer.
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_enableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
                // We'd like to get 60 events per second (in us).
                ASensorEventQueue_setEventRate(engine->sensorEventQueue,
                        engine->accelerometerSensor, (1000L/60)*1000);
            }
            break;
        case APP_CMD_LOST_FOCUS:
            LOGI("Losing focus");
            // When our app loses focus, we stop monitoring the accelerometer.
            // This is to avoid consuming battery while not being used.
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_disableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
            }
            // Also stop animating.
            engine->animating = 0;
            [engine drawFrame];
            break;
    }
}

/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
void android_main(struct android_app* app) {
    // Make sure glue isn't stripped.
    app_dummy();

    LOGI("Preparing display");
    Engine * engine = [Engine new];
    app->userData = engine;
    app->onAppCmd = engine_handle_cmd;
    app->onInputEvent = engine_handle_input;
    engine->app = app;

    // Prepare to monitor accelerometer
    LOGI("Initializing sensors");
    engine->sensorManager = ASensorManager_getInstance();
    engine->accelerometerSensor = ASensorManager_getDefaultSensor(engine->sensorManager,
            ASENSOR_TYPE_ACCELEROMETER);
    engine->sensorEventQueue = ASensorManager_createEventQueue(engine->sensorManager,
            app->looper, LOOPER_ID_USER, NULL, NULL);

    if (app->savedState != NULL) {
        // We are starting with a previous saved state; restore from it.
        engine->state = *(struct saved_state*)app->savedState;
    }

    // loop waiting for stuff to do.
    LOGI("Looping");

    while (1) {
        // Read all pending events.
        int ident;
        int events;
        struct android_poll_source* source;

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while ((ident=ALooper_pollAll(engine->animating ? 0 : -1, NULL, &events,
                (void**)&source)) >= 0) {

            // Process this event.
            if (source != NULL) {
                source->process(app, source);
            }

            // If a sensor has data, process it now.
            if (ident == LOOPER_ID_USER) {
                if (engine->accelerometerSensor != NULL) {
                    ASensorEvent event;
                    while (ASensorEventQueue_getEvents(engine->sensorEventQueue,
                            &event, 1) > 0) {
                        //LOGI("accelerometer: x=%f y=%f z=%f",
                        //        event.acceleration.x, event.acceleration.y,
                        //        event.acceleration.z);
                    }
                }
            }

            // Check if we are exiting.
            if (app->destroyRequested != 0) {
                [engine terminateDisplay];
                return;
            }
        }

        if (engine->animating) {
            // Done with events; draw next animation frame.
            engine->state.angle += .01f;
            if (engine->state.angle > 1) {
                engine->state.angle = 0;
            }

            // Drawing is throttled to the screen update rate, so there
            // is no need to do timing here.
            [engine drawFrame];
        }
    }
}

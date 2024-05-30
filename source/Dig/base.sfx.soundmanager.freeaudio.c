#include <unistd.h>
#include <stddef.h> //definition of NULL

//forward declaration
int __startThread();
void __onAppExit();


//global vars
int threadID;
int updateStreamsEnabled = -1; //-1 = auto activate on registering a callback
int updateInterval = 500; //in ms


//definition and variable for callback
typedef int (*intCallback)(void);
intCallback updateStreamManagerCallback;


//register cleanup function
//this is called when the calling programme exits
atexit( __onAppExit );



// === FUNCTIONS ===

void __onAppExit() {
	stopThread();
}



int stopThread() {
	updateStreamsEnabled = 0;

	return 1;
}



int startThread(){
	updateStreamsEnabled = 1;

	return __startThread();
};



int RegisterUpdateStreamManagerCallback ( intCallback callback ) {
	updateStreamManagerCallback = callback;
	if (updateStreamsEnabled == -1)
		startThread();
		
	return 1;
}



void *updateStreamManager(void *v) {
	while(updateStreamsEnabled == 1) {
		//call the blitzmax function which updates the streams buffers
		if(updateStreamManagerCallback != NULL)
			updateStreamManagerCallback();

		//wait some milliseconds till next update
		usleep(updateInterval * 1000);
	}
	return NULL;
}



// === WINDOWS THREADS ===
#ifdef _WIN32
	#include <windows.h>

	HANDLE  thread;
	
	int __startThread(){
		thread = CreateThread(0, 0, updateStreamManager, NULL, 0, &threadID);
		return 0;
	};



// === POSIX THREADS ===
// Linux, Mac
#else
	#include <pthread.h>

	pthread_t  thread;
	
	int __startThread(){
		threadID = pthread_create(&thread, NULL, updateStreamManager, NULL);	
		return 0;
	};
#endif
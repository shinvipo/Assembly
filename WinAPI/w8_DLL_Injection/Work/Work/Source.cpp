#include<iostream>
#include<Windows.h>
#include<TlHelp32.h>

using namespace std;

int main() {
	char dllPath[1000] = "Dll1.dll";

	char desProcess[1000] = "b.exe";

	int PID = 14196;

//	int PID = getPID(desProcess);

	if (PID == 0)	return 0;

	cout << "Enter PID: " << endl;; cin >> PID;

	cout << "Enter DLL path: "<< endl; cin >> dllPath;

	GetFullPathNameA(dllPath, 1000, dllPath, NULL);

	HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE,PID);

	if (hProcess == NULL) {
		cout << "Cannot OpenProcess ..!!" << endl;
		return 0;
	}

	LPVOID pDllPath = VirtualAllocEx(hProcess, 0, strlen(dllPath) + 1, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE);

	WriteProcessMemory(hProcess, pDllPath, (LPVOID)dllPath,strlen(dllPath) + 1, 0);

	HANDLE hLoadThread = CreateRemoteThread(hProcess, 0, 0, (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandleA("Kernel32.dll"), "LoadLibraryA"), pDllPath, 0, 0);

	VirtualFreeEx(hProcess, pDllPath, strlen(dllPath) + 1, MEM_RELEASE);

	return 0;
}
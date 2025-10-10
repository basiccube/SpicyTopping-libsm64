#pragma once

#include <Windows.h>
#include <string>
using namespace std;

#define func extern "C" __declspec(dllexport)
#define false double(0)
#define true double(1)
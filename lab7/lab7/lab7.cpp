// lab7.cpp : Определяет точку входа для приложения.
//

#include "framework.h"
#include "lab7.h"
using namespace std;
#define MAX_LOADSTRING 100
#define ID_COMBOBOX_TOOL 10001
#define ID_BUTTON_CLEAR 10002
#define ID_LABEL_SIZE 10003
#define ID_LABEL_COLOR 10004
#define ID_SCROLLBAR_SIZE 10013
#define ID_SCROLLBAR_RED_COLOR 10014
#define ID_SCROLLBAR_GREEN_COLOR 10015
#define ID_SCROLLBAR_BLUE_COLOR 10016

// Глобальные переменные:
HINSTANCE hInst;                                // текущий экземпляр
WCHAR szTitle[MAX_LOADSTRING];                  // Текст строки заголовка
WCHAR szWindowClass[MAX_LOADSTRING];            // имя класса главного окна

HWND hWndComboBoxTool;
HWND hWndButtonClear;
HWND hWnd;
int wmId;
PAINTSTRUCT ps;
HDC hdc;
static HWND hRedScroll = NULL, hGreenScroll = NULL, hBlueScroll = NULL, hSizeScroll = NULL;
static int RedNum = 100, GreenNum = 200, BlueNum = 150, SizeNum = 5;
static int* posMas[] = { &RedNum, &GreenNum, &BlueNum, &SizeNum };
static HWND* scrollMas[] = { &hRedScroll, &hGreenScroll, &hBlueScroll,  &hSizeScroll };
HBRUSH hBrush; //кисть для рисования эллипса
static RECT EllipseRect; //области отрисовки
int standartHeight = 23;
static int ellipseW = 50, ellipseH = standartHeight * 2 + 150;

const int widthOfWindow = 1000, heightOfWindow = 700;

enum class TOOLS {
	BRUSH,
	RECT,
	RECT2,
	ELLIPSE,
	ELLIPSE2,
	ERASER,
	FILL,
	GRADIENT
};
TOOLS currentTool = TOOLS::BRUSH;
HACCEL hAccelTable;
MSG msg;
// Отправить объявления функций, включенных в этот модуль кода:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);

int prevX = 0, prevY = 0;

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
	_In_opt_ HINSTANCE hPrevInstance,
	_In_ LPWSTR    lpCmdLine,
	_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);


	// TODO: Разместите код здесь.

	// Инициализация глобальных строк
	LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadStringW(hInstance, IDC_LAB7, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	// Выполнить инициализацию приложения:
	if (!InitInstance(hInstance, nCmdShow))
	{
		return FALSE;
	}

	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_LAB7));

	// Цикл основного сообщения:
	while (GetMessage(&msg, nullptr, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return (int)msg.wParam;
}



//
//  ФУНКЦИЯ: MyRegisterClass()
//
//  ЦЕЛЬ: Регистрирует класс окна.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEXW wcex;

	wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style = CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc = WndProc;
	wcex.cbClsExtra = 0;
	wcex.cbWndExtra = 0;
	wcex.hInstance = hInstance;
	wcex.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_LAB7));
	wcex.hCursor = LoadCursor(nullptr, IDC_ARROW);
	wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wcex.lpszMenuName = MAKEINTRESOURCEW(IDC_LAB7);
	wcex.lpszClassName = szWindowClass;
	wcex.hIconSm = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

	return RegisterClassExW(&wcex);
}

//
//   ФУНКЦИЯ: InitInstance(HINSTANCE, int)
//
//   ЦЕЛЬ: Сохраняет маркер экземпляра и создает главное окно
//
//   КОММЕНТАРИИ:
//
//        В этой функции маркер экземпляра сохраняется в глобальной переменной, а также
//        создается и выводится главное окно программы.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
	hInst = hInstance; // Сохранить маркер экземпляра в глобальной переменной

	hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

	if (!hWnd)
	{
		return FALSE;
	}

	ShowWindow(hWnd, nCmdShow);
	UpdateWindow(hWnd);

	return TRUE;
}

struct THREAD_PARAMS
{
	int startX, startY, endX, endY;
	int RColor1, GColor1, BColor1;
	int RColor2, GColor2, BColor2;
};
int map[1000][700] = { 0 };
int rast(int x1, int y1, int x2, int y2)
{
	return round(sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)));
}
DWORD WINAPI fillGradient(LPVOID lpParam)
{
	THREAD_PARAMS* params = (THREAD_PARAMS*)lpParam;
	int x = params->startX;
	int y = params->startY;
	COLORREF targetColor;
	int allRast = rast(params->endX, params->endY, x, y);
	int R = params->RColor1;
	int G = params->GColor1;
	int B = params->BColor1;
	int deltaR = R - params->RColor2;
	int deltaG = G - params->GColor2;
	int deltaB = B - params->BColor2;
	HDC threadHDC;
	//vector<POINT> pixelMap;	
	const int dx[] = { 0,0,1,-1 };
	const int dy[] = { 1,-1,0,0 };
	POINT pixelMap[100000];
	threadHDC = GetDC(hWnd);
	targetColor = GetPixel(threadHDC, x, y);
	//pixelMap.clear();
	POINT pt;
	pt.x = x;
	pt.y = y;
	//pixelMap.push_back(pt);
	int i = 0, j = 0;
	pixelMap[j] = pt;
	queue<POINT> qr;
	qr.push(pt);

	RECT statusRect;
	statusRect.left = 10;
	statusRect.top = 500;
	statusRect.right = 30;
	statusRect.bottom = 520;
	Rectangle(threadHDC, statusRect.left, statusRect.top, statusRect.right, statusRect.bottom);
	while (i <= j)
	{
		for (int r = 0; r < 4; r++)
		{
			int xx = pixelMap[i].x + dx[r];
			int yy = pixelMap[i].y + dy[r];
			if (map[xx][yy] == 0)
				map[xx][yy] = GetPixel(threadHDC, xx, yy);
			if (targetColor == map[xx][yy])
			{
				pt.x = xx;
				pt.y = yy;
				j++;
				map[xx][yy] = targetColor - 1;
				pixelMap[j] = pt;
			}
		}
		i++;
	}
	for (auto pixel : pixelMap)
	{
		double koef = (double)rast(pixel.x, pixel.y, x, y) / allRast;
		int intPart = floor(koef);
		koef -= intPart;
		if (intPart % 2 == 1)
			koef = 1 - koef;
		SetPixel(threadHDC, pixel.x, pixel.y, RGB(R - koef * deltaR, G - koef * deltaG, B - koef * deltaB));
	}
	InvalidateRect(hWnd, &statusRect, TRUE);
	ReleaseDC(hWnd, threadHDC);

	return 0;
}

void OnLButtonDown(int x, int y)
{
	prevX = x;
	prevY = y;
}
void OnLButtonUp(int x, int y)
{
	switch (currentTool)
	{
	case TOOLS::RECT:
	case TOOLS::RECT2:
	case TOOLS::ELLIPSE:
	case TOOLS::ELLIPSE2:
	{
		HDC hdc = GetDC(hWnd);
		HPEN pen = NULL;
		HBRUSH brush = NULL;
		if (currentTool == TOOLS::RECT || currentTool == TOOLS::ELLIPSE)
		{
			pen = CreatePen(PS_SOLID, SizeNum, RGB(RedNum, GreenNum, BlueNum));
			SelectObject(hdc, pen);
		}
		if (currentTool == TOOLS::RECT2 || currentTool == TOOLS::ELLIPSE2)
		{
			pen = CreatePen(PS_SOLID, SizeNum, RGB(RedNum, GreenNum, BlueNum));
			SelectObject(hdc, pen);
			brush = CreateSolidBrush(RGB(RedNum, GreenNum, BlueNum));
			SelectObject(hdc, brush);
		}
		if (currentTool == TOOLS::RECT || currentTool == TOOLS::RECT2)
			Rectangle(hdc, prevX, prevY, x, y);
		if (currentTool == TOOLS::ELLIPSE || currentTool == TOOLS::ELLIPSE2)
			Ellipse(hdc, prevX, prevY, x, y);
		DeleteObject(pen);
		DeleteObject(brush);
		ReleaseDC(hWnd, hdc);
	}
	break;
	case TOOLS::FILL:
	{
		HDC hdc = GetDC(hWnd);
		HBRUSH br = CreateSolidBrush(RGB(RedNum, GreenNum, BlueNum));
		SelectObject(hdc, br);
		ExtFloodFill(hdc, x, y, GetPixel(hdc, x, y), FLOODFILLSURFACE);
		DeleteObject(br);
		ReleaseDC(hWnd, hdc);
	}
	break;
	case TOOLS::GRADIENT:
	{
		THREAD_PARAMS params;
		params.startX = prevX;
		params.startY = prevY;
		params.endX = x;
		params.endY = y;
		params.RColor1 = RedNum;
		params.GColor1 = GreenNum;
		params.BColor1 = BlueNum;
		params.RColor2 = 255 - RedNum;
		params.GColor2 = 255 - GreenNum;
		params.BColor2 = 255 - BlueNum;
		DWORD dwThreadId;
		HANDLE hThread = CreateThread(NULL, 0, fillGradient, &params, 0, &dwThreadId);
		if (!hThread) {
			MessageBox(hWnd, _T("Can not open thread"), _T("Error"), MB_OK);
		}
	}
	break;
	default:
		break;
	}
}
int countLeftMouse = 0;
void OnMouseMove(int x, int y)
{
	if (GetAsyncKeyState(VK_LBUTTON))
		countLeftMouse++;
	else	
		countLeftMouse = 0;
		
	
	if (countLeftMouse > 1)
	{
		if (currentTool == TOOLS::BRUSH || currentTool == TOOLS::ERASER)
		{
			HDC hdc = GetDC(hWnd);
			HPEN pen = NULL;
			if (currentTool == TOOLS::BRUSH)
				pen = CreatePen(PS_SOLID, SizeNum, RGB(RedNum, GreenNum, BlueNum));

			if (currentTool == TOOLS::ERASER)
				pen = CreatePen(PS_SOLID, SizeNum, RGB(255, 255, 255));

			SelectObject(hdc, pen);
			MoveToEx(hdc, prevX, prevY, NULL);
			LineTo(hdc, x, y);
			prevX = x;
			prevY = y;
			DeleteObject(pen);
			ReleaseDC(hWnd, hdc);
		}
	}
}

//
//  ФУНКЦИЯ: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  ЦЕЛЬ: Обрабатывает сообщения в главном окне.
//
//  WM_COMMAND  - обработать меню приложения
//  WM_PAINT    - Отрисовка главного окна
//  WM_DESTROY  - отправить сообщение о выходе и вернуться
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

	switch (message)
	{
	case WM_CREATE:
	{
		//hWnd = hWnd;
		CreateWindow(_T("STATIC"), _T("Size of line"), SS_CENTER | WS_CHILD | WS_VISIBLE,
			10, 10, 150, standartHeight, hWnd, (HMENU)ID_LABEL_SIZE, hInst, NULL);
		hSizeScroll = CreateWindow(_T("SCROLLBAR"), _T(""), WS_CHILD | WS_VISIBLE | SBS_HORZ,
			10, 10 + standartHeight, 150, standartHeight, hWnd, (HMENU)ID_SCROLLBAR_SIZE, hInst, NULL);
		SetScrollRange(hSizeScroll, SB_CTL, 1, 50, TRUE);
		SetScrollPos(hSizeScroll, SB_CTL, SizeNum, TRUE);


		CreateWindow(_T("STATIC"), _T("Color"), SS_CENTER | WS_CHILD | WS_VISIBLE,
			10, 10 + (10 + standartHeight) * 2, (10 + standartHeight) * 3 - 10, standartHeight, hWnd, (HMENU)ID_LABEL_COLOR, hInst, NULL);

		CreateWindow(_T("STATIC"), _T("R"), SS_CENTER | WS_CHILD | WS_VISIBLE,
			10, (10 + standartHeight) * 3, standartHeight, standartHeight, hWnd, NULL, hInst, NULL);
		CreateWindow(_T("STATIC"), _T("G"), SS_CENTER | WS_CHILD | WS_VISIBLE,
			10 + 10 + standartHeight, (10 + standartHeight) * 3, standartHeight, standartHeight, hWnd, NULL, hInst, NULL);
		CreateWindow(_T("STATIC"), _T("B"), SS_CENTER | WS_CHILD | WS_VISIBLE,
			10 + (10 + standartHeight) * 2, (10 + standartHeight) * 3, standartHeight, standartHeight, hWnd, NULL, hInst, NULL);

		hRedScroll = CreateWindow(_T("SCROLLBAR"), _T(""), WS_CHILD | WS_VISIBLE | SBS_VERT,
			10, 20 + (10 + standartHeight) * 3, standartHeight, 150, hWnd, (HMENU)ID_SCROLLBAR_RED_COLOR, hInst, NULL);
		SetScrollRange(hRedScroll, SB_CTL, 0, 255, TRUE);
		SetScrollPos(hRedScroll, SB_CTL, RedNum, TRUE);

		hGreenScroll = CreateWindow(_T("SCROLLBAR"), _T(""), WS_CHILD | WS_VISIBLE | SBS_VERT,
			10 + 10 + standartHeight, 20 + (10 + standartHeight) * 3, standartHeight, 150, hWnd, (HMENU)ID_SCROLLBAR_GREEN_COLOR, hInst, NULL);
		SetScrollRange(hGreenScroll, SB_CTL, 0, 255, TRUE);
		SetScrollPos(hGreenScroll, SB_CTL, GreenNum, TRUE);

		hBlueScroll = CreateWindow(_T("SCROLLBAR"), _T(""), WS_CHILD | WS_VISIBLE | SBS_VERT,
			10 + (10 + standartHeight) * 2, 20 + (10 + standartHeight) * 3, standartHeight, 150, hWnd, (HMENU)ID_SCROLLBAR_BLUE_COLOR, hInst, NULL);
		SetScrollRange(hBlueScroll, SB_CTL, 0, 255, TRUE);
		SetScrollPos(hBlueScroll, SB_CTL, BlueNum, TRUE);

		CreateWindow(_T("BUTTON"), _T("clear"), WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
			10, 20 + (10 + standartHeight) * 3 + 160, 70, standartHeight, hWnd, (HMENU)ID_BUTTON_CLEAR, hInst, NULL);

		CreateWindow(_T("STATIC"), _T("Tool"), SS_CENTER | WS_CHILD | WS_VISIBLE,
			10, 30 + (10 + standartHeight) * 4 + 160, 150, standartHeight, hWnd, NULL, hInst, NULL);

		hWndComboBoxTool = CreateWindow(_T("COMBOBOX"), _T(""), WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST,
			10, 20 + (10 + standartHeight) * 5 + 160, 150, 400, hWnd, (HMENU)ID_COMBOBOX_TOOL, hInst, NULL);
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Brush");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Rectangle");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Solid rectangle");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Ellipse");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Solid ellipse");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Eraser");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Fill color");
		SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_ADDSTRING, 0, (LPARAM)L"Gradient");



		SendMessage(hWndComboBoxTool, CB_SETCURSEL, (WPARAM)0, (LPARAM)0);

		//Задаём границы области перерисовки по эллипсу
		EllipseRect.left = 10 + (10 + standartHeight) * 3 - 10;
		EllipseRect.top = 10 + (10 + standartHeight) * 2 - 10;
		EllipseRect.right = EllipseRect.left + ellipseW + 10;
		EllipseRect.bottom = EllipseRect.top + ellipseH + 10;

	}
	break;
	case WM_COMMAND:
	{
		if (HIWORD(wParam) == CBN_SELCHANGE)
		{
			int ind;
			switch (LOWORD(wParam)) {
			case ID_COMBOBOX_TOOL:
				ind = SendMessage(hWndComboBoxTool, (UINT)CB_GETCURSEL, (WPARAM)0, (LPARAM)0);
				switch (ind) {
				case 0:
					currentTool = TOOLS::BRUSH;
					break;
				case 1:
					currentTool = TOOLS::RECT;
					break;
				case 2:
					currentTool = TOOLS::RECT2;
					break;
				case 3:
					currentTool = TOOLS::ELLIPSE;
					break;
				case 4:
					currentTool = TOOLS::ELLIPSE2;
					break;
				case 5:
					currentTool = TOOLS::ERASER;
					break;
				case 6:
					currentTool = TOOLS::FILL;
					break;
				case 7:
					currentTool = TOOLS::GRADIENT;
					break;
				default:
					break;
				}
				break;
			}
		}
		if (LOWORD(wParam) == ID_BUTTON_CLEAR) {
			InvalidateRect(hWnd, NULL, TRUE);
		}

		wmId = LOWORD(wParam);
		// Разобрать выбор в меню:
		switch (wmId)
		{
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
	}
	break;
	case WM_LBUTTONDOWN:
		OnLButtonDown(LOWORD(lParam), HIWORD(lParam));
		break;

	case WM_LBUTTONUP:
		OnLButtonUp(LOWORD(lParam), HIWORD(lParam));
		break;
	case WM_MOUSEMOVE:
		OnMouseMove(LOWORD(lParam), HIWORD(lParam));
		break;
	case WM_HSCROLL:
	case WM_VSCROLL:
	{
		/*int date;

		date = SendMessage(GetDlgItem(hWnd, ID_COMBOBOX_TOOL), CB_GETCURSEL, 0, 0L);*/

		int i = 0;
		//Проверяем на какой полосе было перемещение
		if (hRedScroll == (HWND)lParam) i = 0;
		if (hGreenScroll == (HWND)lParam) i = 1;
		if (hBlueScroll == (HWND)lParam) i = 2;
		if (hSizeScroll == (HWND)lParam) i = 3;


		switch (LOWORD(wParam)) {

		case SB_PAGERIGHT: //На страницу вправо
			*posMas[i] += 10;
			break;

		case SB_LINERIGHT: //На одну линию вправо
			*posMas[i] += 1;
			break;


		case SB_PAGELEFT: //На страницу влево
			*posMas[i] -= 10;
			break;

		case SB_LINELEFT: //На линию влево
			*posMas[i] -= 1;
			break;

		case SB_TOP: //Максимальное значение
			*posMas[i] = 255;
			break;

		case SB_BOTTOM: //Минимальное значение
			*posMas[i] = 0;
			break;

		case SB_THUMBPOSITION: //Любое перемещение
		case SB_THUMBTRACK:
			*posMas[i] = HIWORD(wParam);
			break;

		default: break;

		}

		//Вспоминаем, какая полоса была сдвинута
		SetScrollPos(*scrollMas[i], SB_CTL, *posMas[i], TRUE);



		//Вызываем сообщение WM_PAINT по перерисовке области
		//эллипса
		InvalidateRect(hWnd, &EllipseRect, 1);

	}
	break;
	case WM_PAINT:
	{
		hdc = BeginPaint(hWnd, &ps);
		HPEN pen = CreatePen(PS_SOLID, SizeNum, NULL);
		HPEN oldPen = (HPEN)SelectObject(hdc, pen);
		SelectObject(hdc, pen);
		//Создаём кисть с новыми цветами
		hBrush = CreateSolidBrush(RGB(RedNum, GreenNum, BlueNum));
		//Делаем её активной
		HBRUSH oldBrush = (HBRUSH)SelectObject(hdc, hBrush);


		//Рисуем эллипс		
		Ellipse(hdc, EllipseRect.left + 10, EllipseRect.top + 10, EllipseRect.right - 10, EllipseRect.bottom - 10);

		SelectObject(hdc, oldBrush);
		DeleteObject(hBrush);
		SelectObject(hdc, oldPen);
		DeleteObject(pen);


		EndPaint(hWnd, &ps);
	}
	break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

// Обработчик сообщений для окна "О программе".
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}

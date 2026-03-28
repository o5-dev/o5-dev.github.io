@echo off
setlocal enabledelayedexpansion
title AutoStrike 3.0 -- Setup
color 0A

echo.
echo  ============================================
echo    AutoStrike 3.0  --  Setup
echo  ============================================
echo.

:: ─────────────────────────────────────────────
:: STEP 1 — Check Python
:: ─────────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python not found.
    echo  Download: https://www.python.org/downloads/
    echo  Tick "Add Python to PATH" when installing!
    echo.
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  Found: %%v

:: ─────────────────────────────────────────────
:: STEP 2 — Install dependencies
:: ─────────────────────────────────────────────
echo.
echo  [1/4] Upgrading pip...
python -m pip install --upgrade pip --quiet

echo  [2/4] Installing pynput + pyinstaller...
python -m pip install pynput pyinstaller --quiet
if errorlevel 1 (
    echo  [ERROR] pip install failed. Check internet connection.
    pause & exit /b 1
)
echo         OK.

:: ─────────────────────────────────────────────
:: STEP 3 — Write autostrike.py to a temp folder
:: ─────────────────────────────────────────────
echo.
echo  [3/4] Preparing source...
set "TMPDIR=%TEMP%\autostrike_build_%RANDOM%"
mkdir "%TMPDIR%"

:: Write the Python source using PowerShell so we don't fight with
:: batch escaping rules for a large embedded script
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$src = @'" & python -c "pass" >nul 2>&1

:: Embed the full autostrike.py via PowerShell here-string
powershell -NoProfile -ExecutionPolicy Bypass -Command " ^
$code = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String( ^
'IiIiCkF1dG9TdHJpa2UgMy4wICDigJMgTW91c2UgQ2xpY2tlciArIEtleSBQcmVzc2VyCl' ^
)) ; " >nul 2>&1

:: --- Simpler approach: use a Python one-liner to write itself out ----
python -c "
import base64, os, sys

src = r'''
\"\"\"
AutoStrike 3.0  -  Mouse Clicker + Key Presser
Requires:  pip install pynput
\"\"\"

import tkinter as tk
from tkinter import ttk
import threading
import time
import json
import os
import sys

try:
    from pynput.mouse import Button, Controller as MouseController
    from pynput.keyboard import Key, Controller as KeyboardController, KeyCode, Listener as KeyListener
    PYNPUT_OK = True
except ImportError:
    PYNPUT_OK = False

mouse_ctrl = MouseController() if PYNPUT_OK else None
kb_ctrl    = KeyboardController() if PYNPUT_OK else None

if getattr(sys, 'frozen', False):
    BASE = os.path.dirname(sys.executable)
else:
    BASE = os.path.dirname(os.path.abspath(__file__))
SAVE_FILE = os.path.join(BASE, 'autostrike_config.json')

BG       = '#0e0f13'
PANEL    = '#14161c'
PANEL2   = '#1a1d26'
BORDER   = '#2a2d3a'
ACCENT   = '#00e5ff'
ACCENT2  = '#ff3c6e'
TEXT     = '#cdd6f4'
MUTED    = '#6c7086'
GREEN    = '#a6e3a1'
RED      = '#f38ba8'
YELLOW   = '#ffe600'

FONT_MONO  = ('Courier New', 9)
FONT_MONO2 = ('Courier New', 11, 'bold')
FONT_UI    = ('Segoe UI', 9)
FONT_UI_B  = ('Segoe UI', 9, 'bold')
FONT_BIG   = ('Segoe UI', 10, 'bold')
FONT_TITLE = ('Courier New', 11, 'bold')
FONT_COUNT = ('Courier New', 16, 'bold')

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def blend(c1, c2, t):
    r1,g1,b1 = hex_to_rgb(c1); r2,g2,b2 = hex_to_rgb(c2)
    return '#{:02x}{:02x}{:02x}'.format(
        int(r1+(r2-r1)*t), int(g1+(g2-g1)*t), int(b1+(b2-b1)*t))

def ms_from_fields(h, m, s, ms):
    return (int(h)*3600 + int(m)*60 + int(s))*1000 + int(ms)

SPECIAL_KEYS = {
    'F1':Key.f1,'F2':Key.f2,'F3':Key.f3,'F4':Key.f4,'F5':Key.f5,
    'F6':Key.f6,'F7':Key.f7,'F8':Key.f8,'F9':Key.f9,'F10':Key.f10,
    'F11':Key.f11,'F12':Key.f12,
    'Space':Key.space,'Enter':Key.enter,'Tab':Key.tab,
    'Backspace':Key.backspace,'Delete':Key.delete,'Escape':Key.esc,
    'Up':Key.up,'Down':Key.down,'Left':Key.left,'Right':Key.right,
    'Home':Key.home,'End':Key.end,'PageUp':Key.page_up,'PageDown':Key.page_down,
    'Insert':Key.insert,'PrintScreen':Key.print_screen,
    'Ctrl':Key.ctrl,'Alt':Key.alt,'Shift':Key.shift,
} if PYNPUT_OK else {}

MODIFIER_KEYS = {'Key.ctrl_l','Key.ctrl_r','Key.alt_l','Key.alt_r',
                 'Key.shift','Key.shift_r','Key.cmd','Key.cmd_r'}

def key_name(k):
    if hasattr(k, 'char') and k.char:
        return k.char.upper()
    s = str(k)
    mapping = {
        'Key.f1':'F1','Key.f2':'F2','Key.f3':'F3','Key.f4':'F4',
        'Key.f5':'F5','Key.f6':'F6','Key.f7':'F7','Key.f8':'F8',
        'Key.f9':'F9','Key.f10':'F10','Key.f11':'F11','Key.f12':'F12',
        'Key.space':'Space','Key.enter':'Enter','Key.tab':'Tab',
        'Key.backspace':'Backspace','Key.delete':'Delete','Key.esc':'Escape',
        'Key.up':'Up','Key.down':'Down','Key.left':'Left','Key.right':'Right',
        'Key.home':'Home','Key.end':'End','Key.page_up':'PageUp','Key.page_down':'PageDown',
        'Key.insert':'Insert','Key.print_screen':'PrintScreen',
        'Key.ctrl_l':'Ctrl','Key.ctrl_r':'Ctrl',
        'Key.alt_l':'Alt','Key.alt_r':'Alt',
        'Key.shift':'Shift','Key.shift_r':'Shift',
    }
    return mapping.get(s, s.replace('Key.','').capitalize())

def resolve_key(name):
    if name in SPECIAL_KEYS:
        return SPECIAL_KEYS[name]
    if len(name) == 1:
        return KeyCode.from_char(name.lower())
    return KeyCode.from_char(name)

def press_combo(combo):
    if not PYNPUT_OK or not combo:
        return
    mods = [n for n in combo if n in ('Ctrl','Alt','Shift')]
    rest = [n for n in combo if n not in ('Ctrl','Alt','Shift')]
    held = []
    try:
        for m in mods:
            k = resolve_key(m)
            kb_ctrl.press(k); held.append(k)
        for r in rest:
            k = resolve_key(r)
            kb_ctrl.press(k); kb_ctrl.release(k)
    finally:
        for h in reversed(held):
            kb_ctrl.release(h)

MOUSE_BUTTONS = {
    'Left':   Button.left,
    'Right':  Button.right,
    'Middle': Button.middle,
} if PYNPUT_OK else {}

def do_click(btn_name, click_type, x=None, y=None):
    if not PYNPUT_OK: return
    btn = MOUSE_BUTTONS.get(btn_name, Button.left)
    n   = {'Single':1,'Double':2,'Triple':3}.get(click_type,1)
    if x is not None and y is not None:
        mouse_ctrl.position = (int(x), int(y))
    for _ in range(n):
        mouse_ctrl.click(btn)

class AutoStrikeApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('AutoStrike 3.0')
        self.resizable(False, False)
        self.configure(bg=BG)
        self.protocol('WM_DELETE_WINDOW', self._on_close)
        self.clicker_running  = False
        self.keypresser_running = False
        self._clicker_thread  = None
        self._key_thread      = None
        self._click_count     = 0
        self._key_count       = 0
        self._click_start     = 0.0
        self._key_start       = 0.0
        self._recording_keys  = False
        self._current_keys    = []
        self._hotkey_mouse    = 'F6'
        self._hotkey_key      = 'F7'
        self._recording_hotkey = None
        self._temp_hotkeys     = {}
        self._hk_listener      = None
        self._build_ui()
        self._load_state()
        self._start_global_listener()
        self._tick()

    def _build_ui(self):
        tb = tk.Frame(self, bg=PANEL2, pady=8)
        tb.pack(fill='x')
        for i,(c,col) in enumerate([(RED,RED),(YELLOW,YELLOW),(GREEN,GREEN)]):
            tk.Label(tb, text='●', fg=col, bg=PANEL2, font=('Arial',10)).pack(side='left', padx=(8 if i==0 else 2,0))
        tk.Label(tb, text='  AUTOSTRIKE // 3.0', fg=ACCENT, bg=PANEL2, font=FONT_TITLE).pack(side='left', padx=6)
        self._status_var = tk.StringVar(value='STOPPED')
        self._status_lbl = tk.Label(tb, textvariable=self._status_var, fg=YELLOW, bg=PANEL2, font=FONT_MONO, padx=8)
        self._status_lbl.pack(side='right', padx=10)
        tab_frame = tk.Frame(self, bg=PANEL2)
        tab_frame.pack(fill='x')
        self._tab_btns = {}
        for name, label in [('mouse','🖱  Mouse Clicker'), ('key','⌨  Key Presser')]:
            b = tk.Button(tab_frame, text=label, bg=PANEL2, fg=MUTED,
                          font=FONT_UI_B, relief='flat', bd=0, padx=18, pady=8,
                          activebackground=PANEL2, cursor='hand2',
                          command=lambda n=name: self._switch_tab(n))
            b.pack(side='left', fill='x', expand=True)
            self._tab_btns[name] = b
        self._tab_underline = tk.Frame(tab_frame, bg=BORDER, height=2)
        self._tab_underline.place(x=0, rely=1.0, anchor='sw', width=270)
        self._nb = tk.Frame(self, bg=BG)
        self._nb.pack(fill='both', expand=True)
        self._panels = {}
        self._panels['mouse'] = self._build_mouse_panel(self._nb)
        self._panels['key']   = self._build_key_panel(self._nb)
        self._switch_tab('mouse')

    def _section(self, parent, label=None, accent=ACCENT):
        outer = tk.Frame(parent, bg=BG, pady=2)
        outer.pack(fill='x', padx=10)
        frame = tk.Frame(outer, bg=PANEL2, bd=0, highlightthickness=1, highlightbackground=BORDER)
        frame.pack(fill='x')
        if label:
            lf = tk.Frame(frame, bg=PANEL2)
            lf.pack(fill='x', padx=10, pady=(7,3))
            tk.Frame(lf, bg=accent, width=3, height=12).pack(side='left')
            tk.Label(lf, text=f'  {label.upper()}', fg=MUTED, bg=PANEL2, font=FONT_MONO).pack(side='left')
        inner = tk.Frame(frame, bg=PANEL2, padx=10, pady=6)
        inner.pack(fill='x')
        return inner

    def _interval_row(self, parent, prefix, accent=ACCENT):
        row = tk.Frame(parent, bg=PANEL2)
        row.pack(fill='x')
        fields = {}
        for lbl, key, w, default in [('Hours',f'{prefix}_h',6,'0'),
                                      ('Mins', f'{prefix}_m',6,'0'),
                                      ('Secs', f'{prefix}_s',6,'0'),
                                      ('Ms',   f'{prefix}_ms',7,'100')]:
            col = tk.Frame(row, bg=PANEL2)
            col.pack(side='left', expand=True, fill='x', padx=3)
            tk.Label(col, text=lbl, fg=MUTED, bg=PANEL2, font=FONT_MONO).pack()
            var = tk.StringVar(value=default)
            e = tk.Entry(col, textvariable=var, width=w, bg=BG, fg=TEXT,
                         insertbackground=TEXT, relief='flat',
                         highlightthickness=1, highlightbackground=BORDER,
                         highlightcolor=accent, font=FONT_MONO2, justify='center')
            e.pack(ipady=4)
            fields[key] = var
            var.trace_add('write', lambda *a: self._save_state())
        return fields

    def _repeat_section(self, parent, prefix, accent=ACCENT):
        inner = self._section(parent, 'Click Repeat' if prefix=='c' else 'Key Repeat', accent)
        mode_var = tk.StringVar(value='forever')
        count_var = tk.StringVar(value='10')
        for val, lbl in [('forever','Repeat until stopped'), ('count','Repeat')]:
            row = tk.Frame(inner, bg=PANEL2)
            row.pack(fill='x', pady=1)
            rb = tk.Radiobutton(row, variable=mode_var, value=val, bg=PANEL2,
                                activebackground=PANEL2, selectcolor=BG,
                                fg=TEXT, font=FONT_UI, relief='flat',
                                command=lambda: self._save_state())
            rb.pack(side='left')
            tk.Label(row, text=lbl, fg=TEXT, bg=PANEL2, font=FONT_UI).pack(side='left')
            if val == 'count':
                e = tk.Entry(row, textvariable=count_var, width=5, bg=BG, fg=TEXT,
                             insertbackground=TEXT, relief='flat',
                             highlightthickness=1, highlightbackground=BORDER,
                             highlightcolor=accent, font=FONT_MONO2, justify='center')
                e.pack(side='left', padx=6, ipady=3)
                tk.Label(row, text='times', fg=MUTED, bg=PANEL2, font=FONT_UI).pack(side='left')
                count_var.trace_add('write', lambda *a: self._save_state())
        mode_var.trace_add('write', lambda *a: self._save_state())
        return mode_var, count_var

    def _build_mouse_panel(self, parent):
        p = tk.Frame(parent, bg=BG)
        cs = tk.Frame(p, bg=PANEL2, highlightthickness=1, highlightbackground=BORDER)
        cs.pack(fill='x', padx=10, pady=(10,4))
        self._c_count_var   = tk.StringVar(value='0')
        self._c_elapsed_var = tk.StringVar(value='0.0s')
        self._c_cps_var     = tk.StringVar(value='0.0')
        for var, lbl in [(self._c_count_var,'Clicks'),(self._c_elapsed_var,'Elapsed'),(self._c_cps_var,'CPS')]:
            col = tk.Frame(cs, bg=PANEL2)
            col.pack(side='left', expand=True, pady=6)
            tk.Label(col, textvariable=var, fg=ACCENT, bg=PANEL2, font=FONT_COUNT).pack()
            tk.Label(col, text=lbl, fg=MUTED, bg=PANEL2, font=FONT_MONO).pack()
        iv = self._section(p, 'Click Interval', ACCENT)
        self._c_fields = self._interval_row(iv, 'c', ACCENT)
        cols = tk.Frame(p, bg=BG)
        cols.pack(fill='x', padx=10, pady=2)
        left = tk.Frame(cols, bg=PANEL2, highlightthickness=1, highlightbackground=BORDER)
        left.pack(side='left', fill='both', expand=True, padx=(0,4))
        tk.Frame(left, bg=BG).pack()
        lf = tk.Frame(left, bg=PANEL2)
        lf.pack(fill='x', padx=8, pady=(7,3))
        tk.Frame(lf, bg=ACCENT, width=3, height=12).pack(side='left')
        tk.Label(lf, text='  CLICK OPTIONS', fg=MUTED, bg=PANEL2, font=FONT_MONO).pack(side='left')
        li = tk.Frame(left, bg=PANEL2, padx=8, pady=6)
        li.pack(fill='x')
        tk.Label(li, text='Mouse Button', fg=MUTED, bg=PANEL2, font=FONT_MONO).pack(anchor='w')
        self._c_btn_var = tk.StringVar(value='Left')
        cb1 = ttk.Combobox(li, textvariable=self._c_btn_var, values=['Left','Right','Middle'],
                           state='readonly', width=12)
        cb1.pack(fill='x', pady=(2,6), ipady=3)
        cb1.bind('<<ComboboxSelected>>', lambda e: self._save_state())
        tk.Label(li, text='Click Type', fg=MUTED, bg=PANEL2, font=FONT_MONO).pack(anchor='w')
        self._c_type_var = tk.StringVar(value='Single')
        cb2 = ttk.Combobox(li, textvariable=self._c_type_var, values=['Single','Double','Triple'],
                           state='readonly', width=12)
        cb2.pack(fill='x', ipady=3)
        cb2.bind('<<ComboboxSelected>>', lambda e: self._save_state())
        self._style_comboboxes()
        right = tk.Frame(cols, bg=BG)
        right.pack(side='left', fill='both', expand=True)
        self._c_repeat_mode, self._c_repeat_count = self._repeat_section(right, 'c', ACCENT)
        right.children[list(right.children)[-1]].pack_configure(padx=0)
        cur = self._section(p, 'Cursor Position', ACCENT)
        self._c_cursor_var = tk.StringVar(value='current')
        cr = tk.Frame(cur, bg=PANEL2)
        cr.pack(fill='x')
        for val, lbl in [('current','Current location'), ('fixed','Fixed position')]:
            rb = tk.Radiobutton(cr, variable=self._c_cursor_var, value=val,
                                text=lbl, bg=PANEL2, activebackground=PANEL2,
                                selectcolor=BG, fg=TEXT, font=FONT_UI,
                                command=self._update_cursor_ui)
            rb.pack(side='left', padx=(0,10))
        xy = tk.Frame(cur, bg=PANEL2)
        xy.pack(fill='x', pady=(4,0))
        self._c_x_var = tk.StringVar(value='0')
        self._c_y_var = tk.StringVar(value='0')
        self._xy_frame = xy
        for lbl, var in [('X:', self._c_x_var), ('Y:', self._c_y_var)]:
            tk.Label(xy, text=lbl, fg=MUTED, bg=PANEL2, font=FONT_UI).pack(side='left', padx=(4,2))
            e = tk.Entry(xy, textvariable=var, width=7, bg=BG, fg=TEXT,
                         insertbackground=TEXT, relief='flat',
                         highlightthickness=1, highlightbackground=BORDER,
                         highlightcolor=ACCENT, font=FONT_MONO2, justify='center')
            e.pack(side='left', ipady=3, padx=(0,8))
            var.trace_add('write', lambda *a: self._save_state())
        self._c_cursor_var.trace_add('write', lambda *a: self._save_state())
        self._update_cursor_ui()
        ab = tk.Frame(p, bg=BG)
        ab.pack(fill='x', padx=10, pady=(8,3))
        self._c_start_btn = tk.Button(ab, text=f'▶  Start ({self._hotkey_mouse})',
            bg=PANEL2, fg=ACCENT, font=FONT_BIG, relief='flat', bd=0, padx=10, pady=10,
            highlightthickness=1, highlightbackground=ACCENT,
            activebackground=PANEL2, cursor='hand2',
            command=self.toggle_clicker)
        self._c_start_btn.pack(side='left', fill='x', expand=True, padx=(0,4))
        self._c_stop_btn = tk.Button(ab, text=f'■  Stop ({self._hotkey_mouse})',
            bg=PANEL2, fg=MUTED, font=FONT_BIG, relief='flat', bd=0, padx=10, pady=10,
            highlightthickness=1, highlightbackground=BORDER,
            activebackground=PANEL2, cursor='hand2',
            command=self.stop_clicker, state='disabled')
        self._c_stop_btn.pack(side='left', fill='x', expand=True)
        bb = tk.Frame(p, bg=BG)
        bb.pack(fill='x', padx=10, pady=(0,10))
        tk.Button(bb, text='⌨  Hotkey Settings', bg=PANEL2, fg=MUTED, font=FONT_UI_B,
                  relief='flat', bd=0, pady=7,
                  highlightthickness=1, highlightbackground=BORDER,
                  activebackground=PANEL2, cursor='hand2',
                  command=self._open_hotkey_modal).pack(side='left', fill='x', expand=True, padx=(0,4))
        tk.Button(bb, text='↺  Reset Counters', bg=PANEL2, fg=MUTED, font=FONT_UI_B,
                  relief='flat', bd=0, pady=7,
                  highlightthickness=1, highlightbackground=BORDER,
                  activebackground=PANEL2, cursor='hand2',
                  command=self._reset_counters).pack(side='left', fill='x', expand=True)
        return p

    def _style_comboboxes(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('TCombobox',
            fieldbackground=BG, background=PANEL2, foreground=TEXT,
            selectbackground=PANEL2, selectforeground=TEXT,
            arrowcolor=MUTED, bordercolor=BORDER, lightcolor=BORDER,
            darkcolor=BORDER, relief='flat')
        style.map('TCombobox', fieldbackground=[('readonly',BG)])

    def _build_key_panel(self, parent):
        p = tk.Frame(parent, bg=BG)
        cs = tk.Frame(p, bg=PANEL2, highlightthickness=1, highlightbackground=BORDER)
        cs.pack(fill='x', padx=10, pady=(10,4))
        self._k_count_var   = tk.StringVar(value='0')
        self._k_elapsed_var = tk.StringVar(value='0.0s')
        self._k_kps_var     = tk.StringVar(value='0.0')
        for var, lbl in [(self._k_count_var,'Presses'),(self._k_elapsed_var,'Elapsed'),(self._k_kps_var,'KPS')]:
            col = tk.Frame(cs, bg=PANEL2)
            col.pack(side='left', expand=True, pady=6)
            tk.Label(col, textvariable=var, fg=ACCENT2, bg=PANEL2, font=FONT_COUNT).pack()
            tk.Label(col, text=lbl, fg=MUTED, bg=PANEL2, font=FONT_MONO).pack()
        iv = self._section(p, 'Key Press Interval', ACCENT2)
        self._k_fields = self._interval_row(iv, 'k', ACCENT2)
        cols2 = tk.Frame(p, bg=BG)
        cols2.pack(fill='x', padx=10, pady=2)
        left2 = tk.Frame(cols2, bg=PANEL2, highlightthickness=1, highlightbackground=BORDER)
        left2.pack(side='left', fill='both', expand=True, padx=(0,4))
        lf2 = tk.Frame(left2, bg=PANEL2)
        lf2.pack(fill='x', padx=8, pady=(7,3))
        tk.Frame(lf2, bg=ACCENT2, width=3, height=12).pack(side='left')
        tk.Label(lf2, text='  KEYS TO PRESS', fg=MUTED, bg=PANEL2, font=FONT_MONO).pack(side='left')
        ki = tk.Frame(left2, bg=PANEL2, padx=8, pady=6)
        ki.pack(fill='x')
        self._key_display_var = tk.StringVar(value='No keys recorded')
        kd = tk.Label(ki, textvariable=self._key_display_var, fg=MUTED, bg=BG,
                      font=FONT_MONO, anchor='w', padx=8, pady=6,
                      highlightthickness=1, highlightbackground=BORDER, width=22, wraplength=180)
        kd.pack(fill='x', pady=(0,5))
        self._key_disp_lbl = kd
        rec_row = tk.Frame(ki, bg=PANEL2)
        rec_row.pack(fill='x')
        self._rec_btn = tk.Button(rec_row, text='● REC', bg=PANEL2, fg=ACCENT2,
                                   font=FONT_UI_B, relief='flat', bd=0, padx=10, pady=5,
                                   highlightthickness=1, highlightbackground=ACCENT2,
                                   activebackground=PANEL2, cursor='hand2',
                                   command=self._toggle_key_record)
        self._rec_btn.pack(side='left', padx=(0,4))
        tk.Button(rec_row, text='✕ Clear', bg=PANEL2, fg=MUTED,
                  font=FONT_UI_B, relief='flat', bd=0, padx=8, pady=5,
                  highlightthickness=1, highlightbackground=BORDER,
                  activebackground=PANEL2, cursor='hand2',
                  command=self._clear_keys).pack(side='left')
        tk.Label(ki, text='Click REC then press your combo', fg=MUTED, bg=PANEL2,
                 font=FONT_MONO).pack(anchor='w', pady=(4,0))
        right2 = tk.Frame(cols2, bg=BG)
        right2.pack(side='left', fill='both', expand=True)
        self._k_repeat_mode, self._k_repeat_count = self._repeat_section(right2, 'k', ACCENT2)
        right2.children[list(right2.children)[-1]].pack_configure(padx=0)
        ab = tk.Frame(p, bg=BG)
        ab.pack(fill='x', padx=10, pady=(8,3))
        self._k_start_btn = tk.Button(ab, text=f'▶  Start ({self._hotkey_key})',
            bg=PANEL2, fg=ACCENT2, font=FONT_BIG, relief='flat', bd=0, padx=10, pady=10,
            highlightthickness=1, highlightbackground=ACCENT2,
            activebackground=PANEL2, cursor='hand2',
            command=self.toggle_keypresser)
        self._k_start_btn.pack(side='left', fill='x', expand=True, padx=(0,4))
        self._k_stop_btn = tk.Button(ab, text=f'■  Stop ({self._hotkey_key})',
            bg=PANEL2, fg=MUTED, font=FONT_BIG, relief='flat', bd=0, padx=10, pady=10,
            highlightthickness=1, highlightbackground=BORDER,
            activebackground=PANEL2, cursor='hand2',
            command=self.stop_keypresser, state='disabled')
        self._k_stop_btn.pack(side='left', fill='x', expand=True)
        bb = tk.Frame(p, bg=BG)
        bb.pack(fill='x', padx=10, pady=(0,10))
        tk.Button(bb, text='⌨  Hotkey Settings', bg=PANEL2, fg=MUTED, font=FONT_UI_B,
                  relief='flat', bd=0, pady=7,
                  highlightthickness=1, highlightbackground=BORDER,
                  activebackground=PANEL2, cursor='hand2',
                  command=self._open_hotkey_modal).pack(side='left', fill='x', expand=True, padx=(0,4))
        tk.Button(bb, text='↺  Reset Counters', bg=PANEL2, fg=MUTED, font=FONT_UI_B,
                  relief='flat', bd=0, pady=7,
                  highlightthickness=1, highlightbackground=BORDER,
                  activebackground=PANEL2, cursor='hand2',
                  command=self._reset_counters).pack(side='left', fill='x', expand=True)
        return p

    def _switch_tab(self, tab):
        self._active_tab = tab
        for name, panel in self._panels.items():
            if name == tab:
                panel.pack(fill='both', expand=True)
            else:
                panel.pack_forget()
        for name, btn in self._tab_btns.items():
            if name == tab:
                color = ACCENT if tab == 'mouse' else ACCENT2
                btn.configure(fg=color)
            else:
                btn.configure(fg=MUTED)

    def toggle_clicker(self):
        if self.clicker_running: self.stop_clicker()
        else: self.start_clicker()

    def start_clicker(self):
        if self.clicker_running: return
        self.clicker_running = True
        self._click_count = 0
        self._click_start = time.time()
        ms = max(1, ms_from_fields(
            self._c_fields['c_h'].get() or 0,
            self._c_fields['c_m'].get() or 0,
            self._c_fields['c_s'].get() or 0,
            self._c_fields['c_ms'].get() or 100))
        mode  = self._c_repeat_mode.get()
        maxit = int(self._c_repeat_count.get() or 10)
        btn_n = self._c_btn_var.get()
        typ   = self._c_type_var.get()
        cur   = self._c_cursor_var.get()
        cx    = self._c_x_var.get() if cur == 'fixed' else None
        cy    = self._c_y_var.get() if cur == 'fixed' else None
        self._c_start_btn.configure(fg=GREEN, text='■  Running...')
        self._c_stop_btn.configure(state='normal', fg=ACCENT2, highlightbackground=ACCENT2)
        self._update_status()
        def run():
            while self.clicker_running:
                do_click(btn_n, typ, cx, cy)
                self._click_count += 1
                if mode == 'count' and self._click_count >= maxit:
                    self.after(0, self.stop_clicker)
                    break
                time.sleep(ms / 1000.0)
        self._clicker_thread = threading.Thread(target=run, daemon=True)
        self._clicker_thread.start()

    def stop_clicker(self):
        if not self.clicker_running: return
        self.clicker_running = False
        self._c_start_btn.configure(fg=ACCENT, text=f'▶  Start ({self._hotkey_mouse})')
        self._c_stop_btn.configure(state='disabled', fg=MUTED, highlightbackground=BORDER)
        self._update_status()

    def toggle_keypresser(self):
        if self.keypresser_running: self.stop_keypresser()
        else: self.start_keypresser()

    def start_keypresser(self):
        if self.keypresser_running: return
        if not self._current_keys:
            tk.messagebox.showwarning('No keys', 'Please record a key combination first.')
            return
        self.keypresser_running = True
        self._key_count = 0
        self._key_start = time.time()
        ms = max(1, ms_from_fields(
            self._k_fields['k_h'].get() or 0,
            self._k_fields['k_m'].get() or 0,
            self._k_fields['k_s'].get() or 0,
            self._k_fields['k_ms'].get() or 100))
        mode  = self._k_repeat_mode.get()
        maxit = int(self._k_repeat_count.get() or 10)
        combo = list(self._current_keys)
        self._k_start_btn.configure(fg=GREEN, text='■  Running...')
        self._k_stop_btn.configure(state='normal', fg=ACCENT2, highlightbackground=ACCENT2)
        self._update_status()
        def run():
            while self.keypresser_running:
                press_combo(combo)
                self._key_count += 1
                if mode == 'count' and self._key_count >= maxit:
                    self.after(0, self.stop_keypresser)
                    break
                time.sleep(ms / 1000.0)
        self._key_thread = threading.Thread(target=run, daemon=True)
        self._key_thread.start()

    def stop_keypresser(self):
        if not self.keypresser_running: return
        self.keypresser_running = False
        self._k_start_btn.configure(fg=ACCENT2, text=f'▶  Start ({self._hotkey_key})')
        self._k_stop_btn.configure(state='disabled', fg=MUTED, highlightbackground=BORDER)
        self._update_status()

    def _toggle_key_record(self):
        if self._recording_keys: self._stop_key_record()
        else: self._start_key_record()

    def _start_key_record(self):
        self._recording_keys = True
        self._current_keys = []
        self._rec_btn.configure(text='◼ STOP', highlightbackground=ACCENT2)
        self._key_disp_lbl.configure(fg=ACCENT2, highlightbackground=ACCENT2)
        self._key_display_var.set('Press your combo...')

    def _stop_key_record(self):
        self._recording_keys = False
        self._rec_btn.configure(text='● REC', highlightbackground=ACCENT2)
        self._key_disp_lbl.configure(highlightbackground=BORDER)
        self._render_key_display()
        self._save_state()

    def _clear_keys(self):
        self._current_keys = []
        self._render_key_display()
        self._save_state()

    def _render_key_display(self):
        if not self._current_keys:
            self._key_display_var.set('No keys recorded')
            self._key_disp_lbl.configure(fg=MUTED)
        else:
            self._key_display_var.set('  +  '.join(self._current_keys))
            self._key_disp_lbl.configure(fg=ACCENT2)

    def _start_global_listener(self):
        if not PYNPUT_OK: return
        self._currently_pressed = set()
        def on_press(k):
            name = key_name(k)
            self._currently_pressed.add(name)
            if self._recording_keys:
                mods = [n for n in self._currently_pressed if n in ('Ctrl','Alt','Shift')]
                rest = [n for n in self._currently_pressed if n not in ('Ctrl','Alt','Shift')]
                self._current_keys = mods + rest
                self._render_key_display()
                return
            if self._recording_hotkey:
                mods = [n for n in self._currently_pressed if n in ('Ctrl','Alt','Shift')]
                rest = [n for n in self._currently_pressed if n not in ('Ctrl','Alt','Shift')]
                combo = '+'.join(mods + rest)
                if rest:
                    self._temp_hotkeys[self._recording_hotkey] = combo
                    self._recording_hotkey = None
                    self.after(0, self._refresh_hotkey_modal_display)
                return
            mods = [n for n in self._currently_pressed if n in ('Ctrl','Alt','Shift')]
            rest = [n for n in self._currently_pressed if n not in ('Ctrl','Alt','Shift')]
            combo = '+'.join(mods + rest)
            if combo == self._hotkey_mouse:
                self.after(0, self.toggle_clicker)
            if combo == self._hotkey_key:
                self.after(0, self.toggle_keypresser)
        def on_release(k):
            name = key_name(k)
            self._currently_pressed.discard(name)
            if self._recording_keys:
                self.after(0, self._stop_key_record)
        self._hk_listener = KeyListener(on_press=on_press, on_release=on_release)
        self._hk_listener.daemon = True
        self._hk_listener.start()

    def _open_hotkey_modal(self):
        self._temp_hotkeys = {**{'mouse': self._hotkey_mouse, 'key': self._hotkey_key}}
        self._recording_hotkey = None
        modal = tk.Toplevel(self)
        modal.title('Hotkey Settings')
        modal.configure(bg=PANEL)
        modal.resizable(False, False)
        modal.transient(self)
        modal.grab_set()
        self._modal = modal
        tk.Label(modal, text='// HOTKEY SETTINGS', fg=ACCENT, bg=PANEL, font=FONT_TITLE,
                 pady=8).pack(padx=20, anchor='w')
        tk.Frame(modal, bg=BORDER, height=1).pack(fill='x')
        self._hk_labels = {}
        self._hk_rec_btns = {}
        for which, label, default in [
            ('mouse','Mouse Clicker Toggle', self._hotkey_mouse),
            ('key',  'Key Presser Toggle',   self._hotkey_key)
        ]:
            row_frame = tk.Frame(modal, bg=PANEL)
            row_frame.pack(fill='x', padx=20, pady=(12,0))
            tk.Label(row_frame, text=label.upper(), fg=MUTED, bg=PANEL,
                     font=FONT_MONO).pack(anchor='w')
            inner = tk.Frame(modal, bg=PANEL)
            inner.pack(fill='x', padx=20, pady=(4,0))
            lbl = tk.Label(inner, text=self._temp_hotkeys[which], fg=ACCENT, bg=BG,
                           font=FONT_MONO2, anchor='w', padx=10, pady=6,
                           highlightthickness=1, highlightbackground=BORDER, width=20)
            lbl.pack(side='left', fill='x', expand=True, padx=(0,8))
            self._hk_labels[which] = lbl
            rec_btn = tk.Button(inner, text='REC', bg=PANEL2, fg=MUTED,
                                font=FONT_MONO, relief='flat', bd=0, padx=12, pady=5,
                                highlightthickness=1, highlightbackground=BORDER,
                                activebackground=PANEL2, cursor='hand2',
                                command=lambda w=which: self._start_record_hotkey(w))
            rec_btn.pack(side='left')
            self._hk_rec_btns[which] = rec_btn
        tk.Frame(modal, bg=BORDER, height=1).pack(fill='x', pady=(16,0))
        btn_row = tk.Frame(modal, bg=PANEL, pady=12)
        btn_row.pack(fill='x', padx=20)
        tk.Button(btn_row, text='SAVE', bg=PANEL2, fg=ACCENT, font=FONT_BIG,
                  relief='flat', bd=0, padx=20, pady=8,
                  highlightthickness=1, highlightbackground=ACCENT,
                  activebackground=PANEL2, cursor='hand2',
                  command=self._save_hotkeys).pack(side='left', padx=(0,8))
        tk.Button(btn_row, text='CANCEL', bg=PANEL2, fg=MUTED, font=FONT_BIG,
                  relief='flat', bd=0, padx=20, pady=8,
                  highlightthickness=1, highlightbackground=BORDER,
                  activebackground=PANEL2, cursor='hand2',
                  command=modal.destroy).pack(side='left')

    def _start_record_hotkey(self, which):
        self._recording_hotkey = which
        for w, btn in self._hk_rec_btns.items():
            if w == which:
                btn.configure(fg=ACCENT, highlightbackground=ACCENT)
                self._hk_labels[w].configure(text='Press key...', fg=ACCENT,
                                             highlightbackground=ACCENT)
            else:
                btn.configure(fg=MUTED, highlightbackground=BORDER)

    def _refresh_hotkey_modal_display(self):
        if not hasattr(self, '_hk_labels'): return
        for which, lbl in self._hk_labels.items():
            val = self._temp_hotkeys.get(which, '')
            lbl.configure(text=val, fg=ACCENT, highlightbackground=BORDER)
        for btn in self._hk_rec_btns.values():
            btn.configure(fg=MUTED, highlightbackground=BORDER)

    def _save_hotkeys(self):
        self._hotkey_mouse = self._temp_hotkeys.get('mouse', 'F6')
        self._hotkey_key   = self._temp_hotkeys.get('key',   'F7')
        self._c_start_btn.configure(text=f'▶  Start ({self._hotkey_mouse})')
        self._c_stop_btn.configure(text=f'■  Stop ({self._hotkey_mouse})')
        self._k_start_btn.configure(text=f'▶  Start ({self._hotkey_key})')
        self._k_stop_btn.configure(text=f'■  Stop ({self._hotkey_key})')
        self._save_state()
        self._modal.destroy()

    def _update_cursor_ui(self):
        fixed = self._c_cursor_var.get() == 'fixed'
        for w in self._xy_frame.winfo_children():
            w.configure(state='normal' if fixed else 'disabled')

    def _update_status(self):
        if self.clicker_running or self.keypresser_running:
            self._status_var.set('RUNNING')
            self._status_lbl.configure(fg=GREEN)
        else:
            self._status_var.set('STOPPED')
            self._status_lbl.configure(fg=YELLOW)

    def _reset_counters(self):
        self._click_count = 0; self._key_count = 0
        self._click_start = time.time(); self._key_start = time.time()
        self._c_count_var.set('0'); self._c_elapsed_var.set('0.0s'); self._c_cps_var.set('0.0')
        self._k_count_var.set('0'); self._k_elapsed_var.set('0.0s'); self._k_kps_var.set('0.0')

    def _tick(self):
        if self.clicker_running and self._click_start:
            el = time.time() - self._click_start
            self._c_count_var.set(str(self._click_count))
            self._c_elapsed_var.set(f'{el:.1f}s')
            cps = self._click_count / el if el > 0 else 0
            self._c_cps_var.set(f'{cps:.1f}')
        if self.keypresser_running and self._key_start:
            el = time.time() - self._key_start
            self._k_count_var.set(str(self._key_count))
            self._k_elapsed_var.set(f'{el:.1f}s')
            kps = self._key_count / el if el > 0 else 0
            self._k_kps_var.set(f'{kps:.1f}')
        self.after(100, self._tick)

    def _save_state(self):
        try:
            state = {
                'c_h':  self._c_fields['c_h'].get(),
                'c_m':  self._c_fields['c_m'].get(),
                'c_s':  self._c_fields['c_s'].get(),
                'c_ms': self._c_fields['c_ms'].get(),
                'c_btn':    self._c_btn_var.get(),
                'c_type':   self._c_type_var.get(),
                'c_repeat': self._c_repeat_mode.get(),
                'c_repeat_count': self._c_repeat_count.get(),
                'c_cursor': self._c_cursor_var.get(),
                'c_x': self._c_x_var.get(),
                'c_y': self._c_y_var.get(),
                'k_h':  self._k_fields['k_h'].get(),
                'k_m':  self._k_fields['k_m'].get(),
                'k_s':  self._k_fields['k_s'].get(),
                'k_ms': self._k_fields['k_ms'].get(),
                'k_repeat': self._k_repeat_mode.get(),
                'k_repeat_count': self._k_repeat_count.get(),
                'keys': self._current_keys,
                'hotkey_mouse': self._hotkey_mouse,
                'hotkey_key':   self._hotkey_key,
            }
            with open(SAVE_FILE, 'w') as f:
                json.dump(state, f, indent=2)
        except Exception:
            pass

    def _load_state(self):
        try:
            with open(SAVE_FILE) as f:
                s = json.load(f)
            self._c_fields['c_h'].set(s.get('c_h','0'))
            self._c_fields['c_m'].set(s.get('c_m','0'))
            self._c_fields['c_s'].set(s.get('c_s','0'))
            self._c_fields['c_ms'].set(s.get('c_ms','100'))
            self._c_btn_var.set(s.get('c_btn','Left'))
            self._c_type_var.set(s.get('c_type','Single'))
            self._c_repeat_mode.set(s.get('c_repeat','forever'))
            self._c_repeat_count.set(s.get('c_repeat_count','10'))
            self._c_cursor_var.set(s.get('c_cursor','current'))
            self._c_x_var.set(s.get('c_x','0'))
            self._c_y_var.set(s.get('c_y','0'))
            self._k_fields['k_h'].set(s.get('k_h','0'))
            self._k_fields['k_m'].set(s.get('k_m','0'))
            self._k_fields['k_s'].set(s.get('k_s','0'))
            self._k_fields['k_ms'].set(s.get('k_ms','100'))
            self._k_repeat_mode.set(s.get('k_repeat','forever'))
            self._k_repeat_count.set(s.get('k_repeat_count','10'))
            self._current_keys = s.get('keys', [])
            self._hotkey_mouse = s.get('hotkey_mouse','F6')
            self._hotkey_key   = s.get('hotkey_key','F7')
            self._render_key_display()
            self._update_cursor_ui()
            self._c_start_btn.configure(text=f'▶  Start ({self._hotkey_mouse})')
            self._c_stop_btn.configure(text=f'■  Stop ({self._hotkey_mouse})')
            self._k_start_btn.configure(text=f'▶  Start ({self._hotkey_key})')
            self._k_stop_btn.configure(text=f'■  Stop ({self._hotkey_key})')
        except Exception:
            pass

    def _on_close(self):
        self.clicker_running   = False
        self.keypresser_running = False
        if self._hk_listener:
            try: self._hk_listener.stop()
            except: pass
        self.destroy()

if __name__ == '__main__':
    import tkinter.messagebox
    app = AutoStrikeApp()
    app.mainloop()
'''

import tempfile, os
tmpdir = os.environ.get('AUTOSTRIKE_TMPDIR', tempfile.gettempdir())
out = os.path.join(tmpdir, 'autostrike.py')
with open(out, 'w', encoding='utf-8') as f:
    f.write(src.strip())
print(out)
" > "%TMPDIR%\pypath.txt"

set /p PY_OUT=<"%TMPDIR%\pypath.txt"
if not exist "%PY_OUT%" (
    echo  [ERROR] Failed to write autostrike.py
    pause & exit /b 1
)

:: ─────────────────────────────────────────────
:: STEP 4 — Build EXE
:: ─────────────────────────────────────────────
echo  [4/4] Building AutoStrike.exe  (30-60 seconds)...
set "AUTOSTRIKE_TMPDIR=%TMPDIR%"
cd /d "%TMPDIR%"

:: ── AUTO-DETECT ICON ──────────────────────────────────────────
:: Place autostrike.ico next to this .bat and it will be used
:: automatically. The .ico file is included in the download package.
if exist "%~dp0autostrike.ico" (
    echo  [icon] Found autostrike.ico - embedding into EXE...
    python -m PyInstaller --onefile --windowed --name AutoStrike --clean --icon="%~dp0autostrike.ico" autostrike.py
) else (
    python -m PyInstaller --onefile --windowed --name AutoStrike --clean autostrike.py
)

if errorlevel 1 (
    echo  [ERROR] PyInstaller build failed.
    pause & exit /b 1
)

if not exist "%TMPDIR%\dist\AutoStrike.exe" (
    echo  [ERROR] dist\AutoStrike.exe not found.
    pause & exit /b 1
)

copy /Y "%TMPDIR%\dist\AutoStrike.exe" "%~dp0AutoStrike.exe" >nul

:: ─────────────────────────────────────────────
:: STEP 5 — Install (shortcuts etc.)
:: ─────────────────────────────────────────────
echo.
echo  ============================================
echo    AutoStrike.exe built!  Installing now...
echo  ============================================
echo.

:: Write the PowerShell installer inline so we truly need only one file
set "PSFILE=%TMPDIR%\_install.ps1"

(
echo $AppName    = "AutoStrike"
echo $Version    = "3.0"
echo $Publisher  = "AutoStrike"
echo $InstallDir = "$env:ProgramFiles\AutoStrike"
echo $ExeSrc     = "%~dp0AutoStrike.exe"
echo.
echo # ── ICON FOR SHORTCUTS ────────────────────────────────────────────
echo $IcoSrc = "%~dp0autostrike.ico"
echo $IcoDst = "$InstallDir\autostrike.ico"
echo if (Test-Path $IcoSrc) { Copy-Item $IcoSrc $IcoDst -Force }
echo $IconRef = if (Test-Path $IcoDst) { $IcoDst } else { "$InstallDir\AutoStrike.exe,0" }
echo # ─────────────────────────────────────────────────────────────────────
echo.
echo Write-Host ""
echo Write-Host "  ============================================" -ForegroundColor Cyan
echo Write-Host "    AutoStrike $Version  --  Installing..." -ForegroundColor Cyan
echo Write-Host "  ============================================" -ForegroundColor Cyan
echo Write-Host ""
echo.
echo if (-not (Test-Path $ExeSrc)) {
echo     Write-Host "  [ERROR] AutoStrike.exe not found." -ForegroundColor Red
echo     Read-Host "  Press Enter to exit"
echo     exit 1
echo }
echo.
echo Write-Host "  [1/5] Creating install folder..." -ForegroundColor Yellow
echo if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force ^| Out-Null }
echo.
echo Write-Host "  [2/5] Copying files..." -ForegroundColor Yellow
echo Copy-Item -Path $ExeSrc -Destination "$InstallDir\AutoStrike.exe" -Force
echo.
echo Write-Host "  [3/5] Writing uninstaller..." -ForegroundColor Yellow
echo $uninstallScript = @"
echo # AutoStrike Uninstaller
echo `$InstallDir = "$InstallDir"
echo if (Test-Path `$InstallDir) { Remove-Item -Recurse -Force `$InstallDir }
echo `$desk = [Environment]::GetFolderPath('Desktop')
echo `$lnk  = "`$desk\AutoStrike.lnk"
echo if (Test-Path `$lnk) { Remove-Item -Force `$lnk }
echo `$sm = [Environment]::GetFolderPath('CommonPrograms')
echo `$smDir = "`$sm\AutoStrike"
echo if (Test-Path `$smDir) { Remove-Item -Recurse -Force `$smDir }
echo Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoStrike" -Recurse -ErrorAction SilentlyContinue
echo Write-Host "AutoStrike has been uninstalled." -ForegroundColor Green
echo Start-Sleep 2
echo "@
echo $uninstallScript ^| Out-File -FilePath "$InstallDir\Uninstall.ps1" -Encoding UTF8
echo @"
echo @echo off
echo powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
echo "@ ^| Out-File -FilePath "$InstallDir\Uninstall.bat" -Encoding ASCII
echo.
echo Write-Host "  [4/5] Creating shortcuts..." -ForegroundColor Yellow
echo $WshShell = New-Object -ComObject WScript.Shell
echo $deskPath = [Environment]::GetFolderPath('Desktop')
echo $shortcut = $WshShell.CreateShortcut("$deskPath\AutoStrike.lnk")
echo $shortcut.TargetPath       = "$InstallDir\AutoStrike.exe"
echo $shortcut.WorkingDirectory = $InstallDir
echo $shortcut.Description      = "AutoStrike 3.0 - Mouse Clicker and Key Presser"
echo $shortcut.IconLocation     = $IconRef
echo $shortcut.Save()
echo.
echo $smPath = [Environment]::GetFolderPath('CommonPrograms')
echo $smDir  = "$smPath\AutoStrike"
echo if (-not (Test-Path $smDir)) { New-Item -ItemType Directory -Path $smDir -Force ^| Out-Null }
echo $smApp = $WshShell.CreateShortcut("$smDir\AutoStrike.lnk")
echo $smApp.TargetPath       = "$InstallDir\AutoStrike.exe"
echo $smApp.WorkingDirectory = $InstallDir
echo $smApp.IconLocation     = $IconRef
echo $smApp.Save()
echo $smUn = $WshShell.CreateShortcut("$smDir\Uninstall AutoStrike.lnk")
echo $smUn.TargetPath  = "$InstallDir\Uninstall.bat"
echo $smUn.Save()
echo.
echo Write-Host "  [5/5] Registering app..." -ForegroundColor Yellow
echo $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoStrike"
echo New-Item -Path $regPath -Force ^| Out-Null
echo Set-ItemProperty -Path $regPath -Name "DisplayName"     -Value "AutoStrike 3.0"
echo Set-ItemProperty -Path $regPath -Name "DisplayVersion"  -Value $Version
echo Set-ItemProperty -Path $regPath -Name "Publisher"       -Value $Publisher
echo Set-ItemProperty -Path $regPath -Name "InstallLocation" -Value $InstallDir
echo Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "$InstallDir\Uninstall.bat"
echo Set-ItemProperty -Path $regPath -Name "DisplayIcon"     -Value $IconRef
echo Set-ItemProperty -Path $regPath -Name "NoModify"        -Value 1 -Type DWord
echo Set-ItemProperty -Path $regPath -Name "NoRepair"        -Value 1 -Type DWord
echo.
echo Write-Host "" 
echo Write-Host "  ============================================" -ForegroundColor Green
echo Write-Host "    AutoStrike 3.0 installed successfully!" -ForegroundColor Green
echo Write-Host "  ============================================" -ForegroundColor Green
echo Write-Host ""
echo $launch = Read-Host "  Launch AutoStrike now? (Y/N)"
echo if ($launch -match '^[Yy]') { Start-Process "$InstallDir\AutoStrike.exe" }
) > "%PSFILE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PSFILE%""' -Wait"

echo.
echo  ============================================
echo    ALL DONE!  AutoStrike is installed.
echo  ============================================
echo.
pause

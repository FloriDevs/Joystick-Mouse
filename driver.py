import time
import serial
from evdev import UInput, ecodes as e

def stream_joystick(port='/dev/ttyACM0', baudrate=9600):
    """Generator, der kontinuierlich Live-Daten vom Arduino streamt."""
    ser = serial.Serial(port, baudrate, timeout=1)
    time.sleep(2)  # Kurze Wartezeit für den Arduino-Reset
    
    try:
        while True:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            if not line:
                continue
                
            parts = line.split(',')
            if len(parts) != 3:
                continue
                
            try:
                x = int(parts[0])
                y = int(parts[1])
                sw = int(parts[2])
                yield x, y, sw
            except ValueError:
                continue
    finally:
        ser.close()

def main():
    capabilities = {
        e.EV_REL: [e.REL_X, e.REL_Y],
        e.EV_KEY: [e.BTN_LEFT],
    }
    ui = UInput(capabilities, name="nano-joystick-mouse")

    center_x = 512
    center_y = 512
    deadzone = 80

    print("Live-Stream gestartet. Joystick-Maus aktiv...")

    for x_val, y_val, sw_val in stream_joystick('/dev/ttyACM0', 9600):
        move_x = 0
        move_y = 0

        if x_val < (center_x - deadzone):
            move_x = -3
        elif x_val > (center_x + deadzone):
            move_x = 3

        if y_val < (center_y - deadzone):
            move_y = -3
        elif y_val > (center_y + deadzone):
            move_y = 3

        if move_x != 0 or move_y != 0:
            ui.write(e.EV_REL, e.REL_X, move_x)
            ui.write(e.EV_REL, e.REL_Y, move_y)
            ui.syn()

        btn_state = 1 if sw_val == 0 else 0
        ui.write(e.EV_KEY, e.BTN_LEFT, btn_state)
        ui.syn()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nBeendet.")

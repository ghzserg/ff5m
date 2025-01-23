## [gcode_macro LOAD_CELL_TARE]
##
## Copyright (C) 2025, Alexander K <https://github.com/drA1ex>
##
## This file may be distributed under the terms of the GNU GPLv3 license
from encodings import search_function

class LoadCellTareGcode:
    def __init__(self, config):
        self.loaded = False

        self.config = config
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object("gcode")
        self.gcode.register_command("LOAD_CELL_TARE", self.cmd_LOAD_CELL_TARE)

    def _lazy_load_printers_objects(self):
        if self.loaded: return

        self.loaded = True
        self.toolhead = self.printer.lookup_object("toolhead")
        self.weight = self.printer.lookup_object("temperature_sensor weightValue")
        self.probe = self.printer.lookup_object("probe")
        self.level_pin = self.printer.lookup_object("gcode_button check_level_pin")
        self.variables = self.printer.lookup_object("save_variables")

    def _run_gcode(self, *cmds: str):
        self.gcode.run_script_from_command("\n".join(cmds))

    def cmd_LOAD_CELL_TARE(self, gcmd):
        self._lazy_load_printers_objects()

        weight = self.weight.last_temp
        threshold_weight = self.variables.allVariables.get("cell_weight", 0)
        alter_cell_tare = self.config.getint("alter_cell_tare", 0)

        gcmd.respond_info(f"Сброс веса тензодатчиков");

        # TODO: Is it okay ???
        if weight < threshold_weight:
            gcmd.respond_info(f"Начальный вес {we} < {threshold_weight}. Пропускаем сброс тензодатчиков.")
            return

        self._query_probe(gcmd)

        # Try to reset 5 times. IDK if there is any reason for this, but the original firmware does it 10 times
        ok = False
        for i in range(10):
            self._cell_tare()

            if self.level_pin.last_state:
                
                gcmd.respond_info(f"Сброс веса тензодатчиков прошел успешно. Вес: {self.weight.last_temp}")
                ok = True
                break

            gcmd.respond_info(f"Проверка {i + 1}. Подтверждения обнуления нет. Вес: {self.weight.last_temp}")

        if not ok:
            if self.weight.last_temp == 0 and alter_cell_tare == 1:
                gcmd.respond_info(f"Установлен режим игнорирования ошибок сброса тензодатчиков. // SAVE_ZMOD_DATA ALTER_CELL_TARE={alter_cell_tare}")
                gcmd.respond_info(f"Сброс веса тензодатчиков завершен. Вес: {self.weight.last_temp}")
            else:
                gcmd.respond_info(f"Вес при ошибке: {self.weight.last_temp}")
                gcmd.respond_info(f"Попробуйте игнорирование ошибок сброса тензодатчиков. // SAVE_ZMOD_DATA ALTER_CELL_TARE=1")
                raise gcmd.error("Ошибка сброса веса тензодатчиков. Читайте FAQ: https://github.com/ghzserg/zmod/wiki/FAQ")

        # If we are here - tare is considered successful
        self._confirm_tare()

    def _query_probe(self, gcmd):
        self._run_gcode("QUERY_PROBE")

        if not self.probe.last_state:
            gcmd.respond_info("Датчик касания не сработал")
            return

        self._run_gcode("SAVE_GCODE_STATE NAME=CELL_TARE")
        self.gcode.run_script_from_command("SAVE_GCODE_STATE NAME=CELL_TARE")

        kin_status = self.toolhead.get_kinematics().get_status(0)
        if "z" not in kin_status['homed_axes']:
            self._run_gcode("G28 Z")
        elif self.toolhead.get_position()[2] < 10:  # position.z
            self._run_gcode(
                "G91",
                "G1 Z5",
                "M400",
                "G4 P500",
                "M400"
            )

        self.gcode.run_script_from_command("RESTORE_GCODE_STATE NAME=CELL_TARE")
        self.gcode.respond_raw("Обнаружена сработка тензодатчика! Убедитесь что стол чист!")

    def _cell_tare(self):
        # Tare is set by toggling level_h1 pin
        timeout = 500
        self._run_gcode(
            "SET_PIN PIN=level_h1 VALUE=0",
            f"G4 P{timeout}",
            f"M400",
            "SET_PIN PIN=level_h1 VALUE=1",
            f"G4 P{timeout}",
            f"M400",
            "SET_PIN PIN=level_h1 VALUE=0",
            f"G4 P{timeout}",
            f"M400",
            "SET_PIN PIN=level_h1 VALUE=1",
            f"G4 P{timeout}",
            f"M400"
        )

    def _confirm_tare(self):
        # Toggle level clear pins.
        # Not sure what the level clear pin does. But we do the same as the stock software.
        timeout = 10
        self._run_gcode(
            "SET_PIN PIN=level_clear VALUE=0",
            f"G4 P{timeout}",
            f"M400",
            "SET_PIN PIN=level_clear VALUE=1",
            f"G4 P{timeout}",
            f"M400"
        )


def load_config(config):
    return LoadCellTareGcode(config)

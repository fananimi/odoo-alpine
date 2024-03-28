#!/usr/bin/env python3
import os
from configparser import ConfigParser
from odoo.tools import config as odoo_config

ODOO_CONFIG_FILE = os.environ['ODOO_RC']
ODOO_CONFIG_SECTIONS = ["options"]
toml_config = {}
for section in ODOO_CONFIG_SECTIONS:
    toml_config[section] = {}

config_parser = ConfigParser()
env_config = os.environ
for variable, value in env_config.items():
    for section in ODOO_CONFIG_SECTIONS:
        try:
            option, key = variable.lower().split("__")
            if option in ODOO_CONFIG_SECTIONS:
                toml_config[option][key] = value
        except ValueError:
            # skip invalid config
            pass

config_maps = odoo_config.casts

# add section
for section in ODOO_CONFIG_SECTIONS:
    config_parser.add_section(section)

for section in ODOO_CONFIG_SECTIONS:
    for config in toml_config[section]:
        value = ""
        try:
            # official odoo config
            config_type = config_maps[config].type
            if config_type == "int":
                value = int(toml_config[section][config])
            elif config_type == "float":
                value = float(toml_config[section][config])
            else:
                value = str(toml_config[section][config])
        except Exception:
            # non represented config
            try:
                # numericable first
                value = int(toml_config[section][config])
            except Exception:
                value = toml_config[section][config]
        finally:
            config_parser[section][config] = str(value)


if __name__ == "__main__":
    with open(ODOO_CONFIG_FILE, "w") as configfile:
        config_parser.write(configfile)

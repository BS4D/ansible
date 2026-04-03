#!/usr/bin/env python
import os

import keyring

dav_user = os.getenv("DAV_USER")
dav_password = os.getenv("DAV_PASSWORD")

if dav_user is None:
    raise RuntimeError("DAV_USER is not defined")
if dav_password is None:
    raise RuntimeError("DAV_PASSWORD is not defined")

current_password = keyring.get_password("vdirsyncer", dav_user)

if current_password != dav_password:
    keyring.set_password("vdirsyncer", dav_user, dav_password)
    print("password updated")

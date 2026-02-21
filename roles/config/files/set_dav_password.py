#!/usr/bin/env python
import os
import keyring

dav_user = os.getenv("DAV_USER")
dav_password = os.getenv("DAV_PASSWORD")

current_password = keyring.get_password('vdirsyncer', dav_user)

if current_password != dav_password:
    keyring.set_password('vdirsyncer', dav_user, dav_password)
    print('password updated')

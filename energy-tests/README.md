# Benchmarking Nextcloud

What is Nextcloud? A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.

Most of the Nextcloud is based of the code supplied in <https://github.com/nextcloud/docker> please refer to this documentation for everything Nextcloud dependent.

We evaluate the two browsers Chromium and Firefox. Also the three databases MariaDB, Postgres and SQLite.

There are two main ways to deploy Nextcloud with docker. One is via apache and one is using FPM.

## Scenarios

Currently there are three different usage scenarios of Nextcloud, orchestrated with different databases and browsers.
All scripts will start of with creating an admin account and installing the recommended apps,  
then each case diverges from that point.
The cases are:

- Event:
  + Login as admin and create a calendar event and validate that it is visible.
- Docs:
  + Login as admin and create a second user.
  + Login as admin and create a text document and then share it with second user
  + Login as both users, open the text document and edit it, making sure the other user sees the text entered
- Talk:
  + Login as admin and create a group chat, allowing guests to join via link
  + Open the group conversation link in 5 browsers as guests
  + Each guest sends a 20KB random text message and validates the other members have received it

These scripts are implemented in Playwright Python

## Playwright files

- `nextcloud_install.py`: Installs Nextcloud and creates a admin user. Also installs all apps that are
  available.
- `nextcloud_create_event.py`: This script logs into Nextcloud and then creates an event and checks if it then  subsequently shows up in the calender view.
- `nextcloud_talk.py`: Login, create group conversation that is open to guests, then open the chat as 5 guests and send messages, validating each message is received by the other chat members.
- `nextcloud_create_user.py`: Logs into Nextcloud as an admin and creates a second user
- `nextcloud_create_doc_and_share.py`: Login as admin and create a text document, sharing it with the second user
- `nextcloud_docs_collaborate.py`: Login as both admin and 2nd user, open the doc and edit it together, validating the edits from the other user.

## Infrastructure

### apache

The compose file is copy pasted from <https://github.com/nextcloud/docker#base-version---apache>
We set a bogus password for `*_ROOT_PASSWORD` and `*_PASSWORD` as the GMT requires environment variables to be set.

### FPM

The compose file is copy pasted from <https://github.com/nextcloud/docker#base-version---fpm>
Again with bogus passwords as with apache.

## Running

You will need to supply the `--skip-unsafe` to the runner as there are ports defined in the `compose.yml`

## Debugging tips

Sometimes the playwright files will fail and it is unclear why. To easily debug this uncomment

```yml
    # volumes:
    #   - /tmp/.X11-unix:/tmp/.X11-unix
    # environment:
    #   DISPLAY: ":0"
```

in the `usage_scenario*.yml` file.
Then enable head full mode by `headless: false,` in the playwright file. Don't forget to `xhost +` on the host system.
If you have multiple displays you will also need to edit the `DISPLAY: ":0"`.

In cases where the script hangs because of a wrong locator, it might be helpful to run the usage scenario in debug mode and then attach a shell to the Playwright container.
Running `playwright codegen -o output.py` from the container and then following the actions of the script can help investigate what exactly is different.

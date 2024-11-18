import contextlib
import os
import sys
from time import time_ns, sleep
import signal
import random
import string

from playwright.sync_api import Playwright, sync_playwright, expect

from helpers.helper_functions import log_note, get_random_text, login_nextcloud, close_modal, timeout_handler

DOMAIN = 'https://ncs'
#DOMAIN = 'http://localhost:8080'

SLEEP_TIME = 1

FILE_PATH = '/tmp/repo/energy-tests/1mb.txt'
#FILE_PATH = '1mb.txt'

def download(playwright: Playwright, browser_name: str, download_url:str ,headless=False ) -> None:
    log_note(f"Launch download browser {browser_name}")

    download_path = os.path.join(os.getcwd(), 'downloads')
    os.makedirs(download_path, exist_ok=True)

    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=headless, downloads_path=download_path)
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=headless,args=["--headless=new"])


    context = browser.new_context(accept_downloads=True, ignore_https_errors=True)
    page = context.new_page()

    try:

        page.goto(download_url)

        download_url = page.locator("#downloadFile").get_attribute("href")

        with page.expect_download() as download_info:
            page.evaluate(f"window.location.href = '{download_url}'")

        download = download_info.value

        download_file_name = download_path + '/' + download.suggested_filename
        download.save_as(download_file_name)

        if os.path.exists(download_file_name):
            if download_file_name_size := os.path.getsize(download_file_name) >= (1 * 1024 * 1024 - 16): # We substract 16 to avoid one off errors
                log_note(f"File {download_file_name} downloaded")
            else:
                log_note(f"File {download_file_name} downloaded and right size: {download_file_name_size}")
                raise ValueError(f"File not the right size")
        else:
            raise FileNotFoundError(f"File download failed")

        log_note('Download worked ok')

        page.close()
        log_note("Close download browser")

    except Exception as e:
        if hasattr(e, 'message'): # only Playwright error class has this member
            log_note(f"Exception occurred: {e.message}")

        # set a timeout. Since the call to page.content() is blocking we need to defer it to the OS
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(20)
        #log_note(f"Page content was: {page.content()}")
        signal.alarm(0) # remove timeout signal

        raise e

    # ---------------------
    context.close()
    browser.close()

def run(playwright: Playwright, browser_name: str, headless=False) -> None:
    log_note(f"Launch browser {browser_name}")
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=headless)
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=headless,args=["--headless=new"])
    context = browser.new_context(ignore_https_errors=True)
    page = context.new_page()

    try:
        page.goto(f"{DOMAIN}/login")
        log_note("Login")
        login_nextcloud(page, domain=DOMAIN)

        log_note("Wait for welcome popup")
        close_modal(page)

        log_note("Go to Files")
        page.get_by_role("link", name="Files").click()

        sleep(SLEEP_TIME)

        log_note("Upload File")

        page.get_by_role("button", name="New").click()

        div_selector = 'div.v-popper__wrapper:has(ul[role="menu"])'
        page.wait_for_selector(div_selector, state='visible')

        file_name = ''.join(random.choices(string.ascii_letters, k=5)) + '.txt'

        with open(FILE_PATH, 'rb') as f:
            file_content = f.read()

        file_payload = {
            'name': file_name,
            'mimeType': 'text/plain',
            'buffer': file_content,
        }

        with page.expect_file_chooser() as fc_info:
            page.locator(f'{div_selector} button:has-text("Upload files")').click()

        file_chooser = fc_info.value
        file_chooser.set_files(file_payload)

        updated_file_locator = page.locator(f'tr[data-cy-files-list-row-name="{file_name}"]')
        expect(updated_file_locator).to_have_count(1)

        # SHARE
        log_note("Share File")

        updated_file_locator.locator('button[data-cy-files-list-row-action="sharing-status"]').click()

        page.locator('button.new-share-link').click()

        toast_selector = 'div.toastify.toast-success:has-text("Link copied")'
        page.wait_for_selector(toast_selector)

        link_url = page.evaluate('navigator.clipboard.readText()')
        log_note(f"Download url is: {link_url}")

        sleep(SLEEP_TIME)

        download(playwright, browser_name, link_url, headless)

        page.close()
        log_note("Close browser")

    except Exception as e:
        if hasattr(e, 'message'): # only Playwright error class has this member
            log_note(f"Exception occurred: {e.message}")

        # set a timeout. Since the call to page.content() is blocking we need to defer it to the OS
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(20)
        #log_note(f"Page content was: {page.content()}")
        signal.alarm(0) # remove timeout signal

        raise e

    # ---------------------
    context.close()
    browser.close()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "firefox"

    with sync_playwright() as playwright:
        run(playwright, browser_name)

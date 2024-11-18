import contextlib
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

        log_note("Go to contacs")
        page.get_by_role("link", name="Contacts").click()

        sleep(SLEEP_TIME)

        #CREATE
        log_note("Create new Contact")
        contact_name = "Gary McKinnon" + ''.join(random.choices(string.ascii_letters, k=5))
        page.get_by_role("button", name="New contact").click()
        page.get_by_placeholder("Name").fill(contact_name)
        page.get_by_role("button", name="Save").click()

        expect(page.get_by_role('heading', name=contact_name)).to_be_visible()
        expect(page.locator('div.list-item-content__name', has_text=contact_name)).to_have_count(1)

        sleep(SLEEP_TIME)

        # EDIT
        log_note("Modify contact")
        page.get_by_role("button", name="Edit").click()
        edit_contact_name = contact_name + ''.join(random.choices(string.ascii_letters, k=5))
        page.get_by_placeholder("Name").fill(edit_contact_name)
        page.get_by_role("button", name="Save").click()

        expect(page.get_by_role('heading', name=edit_contact_name)).to_be_visible()
        expect(page.locator('div.list-item-content__name', has_text=edit_contact_name)).to_have_count(1)

        sleep(SLEEP_TIME)

        # DELETE
        log_note("Delete the contact")

        actions_button = page.locator('button[aria-haspopup="menu"]')
        actions_button.click()

        actions_button_id = actions_button.get_attribute('id')
        menu_id = actions_button_id.replace('trigger-', '')
        menu_selector = f'ul#{menu_id}[role="menu"]'
        menu_locator = page.locator(menu_selector)
        expect(menu_locator).to_be_visible()

        delete_button = menu_locator.locator('button.action-button:has-text("Delete")')
        expect(delete_button).to_be_visible()
        delete_button.click()

        expect(page.locator('div.list-item-content__name', has_text=edit_contact_name)).to_have_count(0)

        sleep(SLEEP_TIME)

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

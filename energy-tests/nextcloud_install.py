import sys
from time import time_ns

from playwright.sync_api import sync_playwright

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def main(browser_name: str = "chromium"):
    with sync_playwright() as playwright:
        log_note(f"Launch browser {browser_name}")
        if browser_name == "firefox":
            browser = playwright.firefox.launch(headless=True)
        else:
            # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
            # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
            browser = playwright.chromium.launch(headless=False,args=["--headless=new"])
        context = browser.new_context()
        page = context.new_page()
        try:
            page.goto('http://nc/')
            page.set_default_timeout(240_000)

            # 1. Create User
            log_note("Create admin user")
            page.type('#adminlogin', 'Crash')
            page.type('#adminpass', 'Override')
            page.click('.primary')

            # 2. Install all Apps
            log_note("Install recommended apps")
            install_selector = '.button-vue--vue-primary'
            page.wait_for_selector(install_selector)
            page.click(install_selector)

            # 3. Dashboard
            page.wait_for_selector('.app-dashboard')
            log_note("Installation complete")
            browser.close()

        except Exception as e:
            if hasattr(e, 'message'): # only Playwright error class has this member
                log_note(f"Exception occurred: {e.message}")
            log_note(f"Page content was: {page.content()}")
            raise e


if __name__ == '__main__':
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "chromium"

    main(browser_name)

from playwright.sync_api import sync_playwright
from time import time

def main():
    with sync_playwright() as playwright:
        browser_type = playwright.chromium
        browser = browser_type.launch(
            headless=False,
            args=["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
        )
        page = browser.new_page()
        page.goto('http://nc/')
        page.set_default_timeout(120_000)

        # 1. Create User
        page.type('#adminlogin', 'Crash')
        page.type('#adminpass', 'Override')
        page.click('.primary')
        print(time(), "Create user clicked")

        # 2. Install all Apps
        install_selector = '.button-vue--vue-primary'
        page.wait_for_selector(install_selector)
        page.click(install_selector)
        print(time(), "Install apps clicked")

        # 3. Dashboard
        page.wait_for_selector('.app-dashboard')
        print(time(), "Dashboard found")

        browser.close()


if __name__ == '__main__':
    main()

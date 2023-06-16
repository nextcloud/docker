from time import time_ns

from playwright.sync_api import sync_playwright

def log_note(message: str) -> None:
    timestamp = round(time_ns() * 1000)
    print(f"{timestamp} {message}")

def main():
    with sync_playwright() as playwright:
        log_note("Launch browser")
        browser_type = playwright.chromium
        browser = browser_type.launch(
            headless=True,
            args=["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
        )
        page = browser.new_page()
        page.goto('http://nc/')
        page.set_default_timeout(180_000)

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


if __name__ == '__main__':
    main()

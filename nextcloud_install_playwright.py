from playwright.sync_api import sync_playwright

def main():
    with sync_playwright() as playwright:
        browser_type = playwright.chromium
        browser = browser_type.launch(
            headless=True,
            args=["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
        )
        page = browser.new_page()
        page.goto('http://nc/')
        page.set_default_timeout(120_000)

        # 1. Create User
        page.type('#adminlogin', 'Crash')
        page.type('#adminpass', 'Override')
        page.click('.primary')

        # 2. Install all Apps
        install_selector = '.button-vue--vue-primary'
        page.wait_for_selector(install_selector)
        page.click(install_selector)

        # 3. Dashboard
        page.wait_for_selector('.app-dashboard')

        browser.close()


if __name__ == '__main__':
    main()

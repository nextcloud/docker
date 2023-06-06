from playwright.async_api import async_playwright
from time import time

async def main():
    async with async_playwright() as playwright:
        browser_type = playwright.chromium
        browser = await browser_type.launch(
            headless=True,
            args=["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"]
        )
        page = await browser.new_page()
        # await page.set_default_timeout(60_000)  # milliseconds
        await page.goto('http://app/')

        # 1. Create User
        await page.type('#adminlogin', 'Crash')
        await page.type('#adminpass', 'Override')
        await page.click('.primary')
        print(time(), "Create user clicked")

        # 2. Install all Apps
        install_selector = '.button-vue--vue-primary'
        await page.wait_for_selector(install_selector)
        await page.click(install_selector)
        print(time(), "Install apps clicked")

        # 3. Dashboard
        await page.wait_for_selector('.app-dashboard')
        print(time(), "Dashboard found")

        await browser.close()


if __name__ == '__main__':
    import asyncio
    asyncio.run(main())

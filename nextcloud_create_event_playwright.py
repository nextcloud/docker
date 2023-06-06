import asyncio
import time
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as playwright:
        browser_type = playwright.chromium
        browser = await browser_type.launch(headless=True, args=["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"])
        page = await browser.new_page()
        # await page.set_default_timeout(60_000)  # milliseconds
        await page.goto('http://app/login')

        # 1. Login
        user_element = await page.wait_for_selector('//*[@data-login-form-input-user]')
        await user_element.type('Crash')
        pass_element = await page.wait_for_selector('//*[@data-login-form-input-password]')
        await pass_element.type('Override')
        await page.click('.button-vue--vue-primary')
        print(time.time(), "Login clicked")

        # Handle unsupported browsers warning
        unsupported_element = await page.wait_for_selector('.content-unsupported-browser__continue')
        if unsupported_element:
            await unsupported_element.click()
            print(time.time(), "Unsupported browsers warning clicked")

        await page.wait_for_navigation(wait_until='domcontentloaded', url='http://app/apps/dashboard/')

        # Wait for the modal to load and close
        await asyncio.sleep(3)

        # 2. Close Modal
        modal_close = await page.wait_for_selector('.modal-container__close')
        await modal_close.click()
        print(time.time(), "Intro video modal clicked")

        # Wait for the modal animation to complete
        await asyncio.sleep(3)

        # 3. Go to Cal
        await page.click('a[href="/apps/calendar/"]')
        print(time.time(), "Calendar clicked")

        # 4. Open New Event Box
        new_event_selector = await page.wait_for_selector('.new-event')
        await new_event_selector.click()
        print(time.time(), "New event clicked")

        # 4. Create Event
        title_selector = await page.wait_for_selector('input[placeholder="Event title"]')
        await title_selector.type('NYC2600 Meeting')
        save_selector = await page.wait_for_selector('text=Save')
        await save_selector.click()
        print(time.time(), "Save event clicked")

        # 5. Wait for the event
        await page.wait_for_selector('text=NYC2600 Meeting')
        print(time.time(), "Event found! Fin")

        await browser.close()


if __name__ == '__main__':
    asyncio.run(main())

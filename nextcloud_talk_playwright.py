from playwright.sync_api import Playwright, sync_playwright


def create_conversation(playwright: Playwright) -> str:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://nc/")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_role("button", name="Log in").click()

    # Wait for the modal to load. As it seems you can't close it while it is showing the opening animation.
    page.get_by_role("button", name="Close modal").click(timeout=15_000)

    page.get_by_role("link", name="Talk", exact=True).click()
    page.wait_for_url("**/apps/spreed/")
    page.get_by_role("button", name="Create a new group conversation").click()
    page.get_by_placeholder("Conversation name").fill("Random talk")
    page.locator("label").filter(has_text="Allow guests to join via link").locator("svg").click()
    page.get_by_role("button", name="Create conversation").click()
    page.get_by_role("button", name="Copy conversation link").click()
    page.close()

    # ---------------------
    context.close()
    browser.close()

    return page.url

def talk(playwright: Playwright, url: str) -> None:
    browser_one = playwright.chromium.launch(headless=True, slow_mo=1500)
    browser_two = playwright.chromium.launch(headless=True, slow_mo=1500)
    context_one = browser_one.new_context()
    context_two = browser_two.new_context()
    user_one = context_one.new_page()
    user_two = context_two.new_page()

    user_one.goto(url)
    user_two.goto(url)
    user_one.get_by_role("button", name="Edit").click()
    user_two.get_by_role("button", name="Edit").click()
    user_one.get_by_placeholder("Guest").fill("Dude#1")
    user_two.get_by_placeholder("Guest").fill("Dude#2")
    user_one.get_by_role("button", name="Save name").click()
    user_two.get_by_role("button", name="Save name").click()

    user_one.get_by_role("textbox", name="Write message, @ to mention someone …").click()
    user_one.get_by_role("textbox", name="Write message, @ to mention someone …").fill("Heya")
    user_one.get_by_role("textbox", name="Write message, @ to mention someone …").press("Enter")

    user_two.get_by_role("textbox", name="Write message, @ to mention someone …").click()
    user_two.get_by_role("textbox", name="Write message, @ to mention someone …").fill("Let's send some /dev/random")
    user_two.get_by_role("textbox", name="Write message, @ to mention someone …").press("Enter")

    user_one.get_by_role("textbox", name="Write message, @ to mention someone …").click()
    user_one.get_by_role("textbox", name="Write message, @ to mention someone …").fill("Lets!")
    user_one.get_by_role("textbox", name="Write message, @ to mention someone …").press("Enter")

    user_one.close()
    user_two.close()

    # ---------------------
    context_one.close()
    context_two.close()
    browser_one.close()
    browser_two.close()


with sync_playwright() as playwright:
    conversation_link = create_conversation(playwright)
    talk(playwright, conversation_link)

import { expect, type Locator, type Page } from "@playwright/test";

export class SensePage {
    readonly page: Page;
    readonly chatSettings: Locator;

    constructor(page: Page) {
        this.page = page;
        this.chatSettings = page.locator("#chat-settings-open-modal");
    }

    async goto() {
        await this.page.goto("/");
    }

    async openChatSettings() {
        await this.chatSettings.click();
    }

    async changeChatSettings() {
        await this.page.getByText("Model").click();
        await this.page.keyboard.press("Enter");
        await this.page.getByText("gpt-4-1106-preview").click();
        await this.page.getByLabel("Memory Length (Message Count)").fill("15");
        await this.page.getByRole("button", { name: "Confirm" }).click();
    }

    async logout() {
        await this.page
            .locator("div")
            .filter({ hasText: /^A$/ })
            .nth(1)
            .click();
        await this.page.getByRole("menuitem", { name: "Logout" }).click();
    }

    async typeAndSendMessage(message: string) {
        await this.page
            .getByPlaceholder("Type your message here...")
            .fill(message);
        await this.page.keyboard.press("Enter");
    }

    async getClipboardContent() {
        const handle = await this.page.evaluateHandle(() =>
            navigator.clipboard.readText(),
        );
        return await handle.jsonValue();
    }
}

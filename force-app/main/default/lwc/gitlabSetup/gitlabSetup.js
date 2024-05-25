import { api, LightningElement } from "lwc";

export default class GitlabSetup extends LightningElement {
    @api
    set initialData(value) {
        this.isNamedCredCreated = !!value.namedCredId;
        this.namedCredUrl = `/lightning/setup/NamedCredential/${value.namedCredId}/view`;
        this.data.hostname = value.gitlabUrl
            ? new URL(value.gitlabUrl).hostname
            : "";
        this.data.tokenPlaceholder = value.isGitlabTokenSet
            ? "•".repeat(26)
            : "";
        this.isNamedCredEnabled = value.isNamedCredEnabled;
    }
    // eslint-disable-next-line no-empty-function,getter-return
    get initialData() {}

    data = {};
    isNamedCredCreated = false;
    isNamedCredEnabled = false;
    namedCredUrl = "";

    get buttonLabel() {
        return this.isNamedCredCreated ? "Update" : "Create";
    }

    handleChange({ currentTarget: { name, value } }) {
        this.data[name] = value;
    }

    save() {
        if (!this.isFormValid()) {
            return;
        }
        const url = "https://" + this.data.hostname;
        this.dispatchEvent(
            new CustomEvent("save", { detail: { url, token: this.data.token } })
        );
    }

    isFormValid() {
        return [...this.template.querySelectorAll(".input")].reduce(
            (validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            },
            true
        );
    }
}

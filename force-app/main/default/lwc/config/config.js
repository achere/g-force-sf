import { LightningElement, track } from "lwc";
import getData from "@salesforce/apex/ConfigController.getData";
import reportConnectedAppToBeSetup from "@salesforce/apex/ConfigController.reportConnectedAppToBeSetup";
import saveNamedCred from "@salesforce/apex/ConfigController.saveNamedCred";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const CONNECTED_APP = "connected_app";
const GITLAB = "gitlab_token";
const BRANCH = "claim_branch";

export default class Config extends LightningElement {
    isConnectedAppReportedToBeSetup = false;
    gitlabData = {};

    isLoading = true;
    get buttonLabel() {
        return this.isLoading ? "Checking..." : "Check Step";
    }

    get isCheckButtonVisible() {
        return this.currentStep !== BRANCH;
    }

    get isCheckButtonDisabled() {
        return (
            this.isLoading ||
            (this.currentStep === CONNECTED_APP &&
                !this.isConnectedAppReportedToBeSetup)
        );
    }

    get isBackButtonVisible() {
        return this.currentStep === BRANCH;
    }

    get isBackButtonDisabled() {
        return (
            this.isLoading ||
            (this.currentStep === CONNECTED_APP &&
                !this.isConnectedAppReportedToBeSetup)
        );
    }

    @track
    steps = {
        [CONNECTED_APP]: true,
        [GITLAB]: false,
        [BRANCH]: false
    };
    stepOrder = [CONNECTED_APP, GITLAB, BRANCH];
    get currentStep() {
        for (const step in this.steps) {
            if (this.steps[step]) {
                return step;
            }
        }
        return CONNECTED_APP;
    }

    switchStep(targetStep) {
        for (const step in this.steps) {
            if (Object.hasOwn(this.steps, step)) {
                this.steps[step] = step === targetStep;
            }
        }
    }

    async connectedCallback() {
        if (
            this.currentStep === CONNECTED_APP &&
            this.isConnectedAppReportedToBeSetup
        ) {
            await reportConnectedAppToBeSetup();
            this.isConnectedAppReportedToBeSetup = false;
        }
        getData()
            .then((json) => {
                this.isLoading = false;
                const data = JSON.parse(json);
                if (!data.isConnectedAppSetup) {
                    this.switchStep(CONNECTED_APP);
                    return;
                }

                // eslint-disable-next-line no-unused-vars
                const { isConnectedAppSetup, ...gitlabData } = data;
                this.gitlabData = gitlabData;
                if (
                    !data.isConnectedAppSetup ||
                    !data.isNamedCredEnabled ||
                    !data.isGitlabTokenSet
                ) {
                    this.switchStep(GITLAB);
                    return;
                }

                this.switchStep(BRANCH);
            })
            .catch(this.handleError);
    }

    checkStep() {
        this.isLoading = true;
        this.connectedCallback();
    }

    backStep() {
        let idx = 0;
        for (const [i, step] of this.stepOrder.entries()) {
            if (this.currentStep === step) {
                idx = i;
            }
        }
        this.switchStep(this.stepOrder[idx - 1 >= 0 ? idx - 1 : 0]);
    }

    handleConnectedAppSetup({ detail: { checked } }) {
        this.isConnectedAppReportedToBeSetup = !!checked;
    }

    handleSaveNamedCred({ detail: { url, token } }) {
        this.isLoading = true;
        saveNamedCred({ url, token })
            .then(() => {
                this.connectedCallback();
            })
            .catch(this.handleError);
    }

    handleSetLoading({ detail }) {
        this.isLoading = detail;
    }

    handleError = (error) => {
        console.error(error);
        this.dispatchEvent(
            new ShowToastEvent({
                variant: "error",
                title: "Error fetching data",
                message: error.body ? error.body.message : error.message
            })
        );
    };
}

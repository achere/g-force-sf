import { LightningElement, track } from "lwc";
import getBranches from "@salesforce/apex/ConfigController.getBranches";
import getProjectIdFromSettings from "@salesforce/apex/ConfigController.getProjectIdFromSettings";
import saveProjectId from "@salesforce/apex/ConfigController.saveProjectId";
import claimBranch from "@salesforce/apex/ConfigController.claimBranch";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ClaimBranch extends LightningElement {
    @track
    data = {};
    @track
    branchOptions = [];
    @track
    apiVersionOptions = [];

    isProjectFound = false;
    get findProjectButtonLabel() {
        return this.isProjectFound ? "Project Saved" : "Find Project";
    }

    isBranchClaimed = false;
    get claimBranchLabel() {
        return this.isBranchClaimed ? "Branch Claimed" : "Claim Branch";
    }

    get isBranchInputDisabled() {
        return !this.isProjectFound || this.isBranchClaimed;
    }
    // eslint-disable-next-line no-empty-function
    set isBranchInputDisabled(value) {}

    connectedCallback() {
        for (let v = 60; v > 41; v--) {
            const apiVersion = v + ".0";
            this.apiVersionOptions.push({
                label: apiVersion,
                value: apiVersion
            });
        }

        this.dispatchEvent(new CustomEvent("setloading", { detail: true }));
        getProjectIdFromSettings()
            .then((projectId) => {
                if (!projectId) {
                    this.dispatchEvent(
                        new CustomEvent("setloading", { detail: false })
                    );
                    return;
                }
                this.data.projectId = projectId;
                this.isProjectFound = true;
                getBranches({ projectId: this.data.projectId })
                    .then(this.handleBranches)
                    .catch(this.handleError);
            })
            .catch(this.handleError);
    }

    handleChange({ currentTarget: { name, value } }) {
        this.data[name] = value;
    }

    findProject() {
        if (!this.refs.projectId.checkValidity()) {
            return;
        }

        getBranches({ projectId: this.data.projectId })
            .then(this.handleBranches)
            .catch(this.handleError);
    }

    handleBranches = (json) => {
        this.dispatchEvent(new CustomEvent("setloading", { detail: false }));

        if (!this.isProjectFound) {
            this.isProjectFound = true;
            saveProjectId({ projectId: this.data.projectId }).catch(
                this.handleError
            );
        }

        this.branchOptions = JSON.parse(json)
            .filter(
                ({ isClaimed, isProtected, isThisOrg }) =>
                    !isProtected && (!isClaimed || isThisOrg)
            )
            .map(({ name, isThisOrg, apiVersion }) => ({
                label: name,
                value: name,
                isThisOrg,
                apiVersion
            }));

        for (const branch of this.branchOptions) {
            if (branch.isThisOrg) {
                this.data.branch = branch.value;
                this.data.apiVersion = branch.apiVersion;
                this.isBranchClaimed = true;
            }
        }

        if (this.branchOptions.length === 1) {
            this.data.branch = this.branchOptions[0].value;
        }
    };

    claimBranch() {
        if (
            ![...this.template.querySelectorAll(".branch")].reduce(
                (validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                },
                true
            )
        ) {
            return;
        }

        claimBranch({
            branchName: this.data.branch,
            apiVersion: this.data.apiVersion
        })
            .then(() => {
                this.isBranchClaimed = true;
            })
            .catch(this.handleError);
    }

    handleError = (error) => {
        this.dispatchEvent(new CustomEvent("setloading", { detail: false }));
        console.error(error);
        this.dispatchEvent(
            new ShowToastEvent({
                variant: "error",
                title: "Error fetching project",
                message: error.body ? error.body.message : error.message
            })
        );
    };
}

import { LightningElement } from "lwc";

export default class ConnectedAppSetup extends LightningElement {
    handleCheckbox({ currentTarget: { checked } }) {
        this.dispatchEvent(
            new CustomEvent("connectedappreportedsetup", {
                detail: { checked }
            })
        );
    }
}

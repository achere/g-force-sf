import { api, LightningElement } from "lwc";

export default class ConfigStep extends LightningElement {
    _isLoading = true;
    @api get isLoading() {
        return this._isLoading;
    }
    set isLoading(value) {
        this._isLoading = value;
    }
    @api title;
}

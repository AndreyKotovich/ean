import { LightningElement } from 'lwc';
export default class AbstractSubmission extends LightningElement {

    getPDF(event){
        window.open(`${window.location.origin}/apex/AbstractBooks?type=AbstractSubmission`, '_blank');
    }
}
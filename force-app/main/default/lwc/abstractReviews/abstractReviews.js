import { LightningElement } from 'lwc';

export default class AbstractReviews extends LightningElement {
    getPDF(event){
        window.open(`${window.location.origin}/apex/AbstractBooks?type=AbstractReviews`, '_blank');
    }
}
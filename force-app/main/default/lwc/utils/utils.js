export class Utils {

    static validateElements(querySelectorCriteria){
        const allValid = [...this.template.querySelectorAll(querySelectorCriteria)]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

}
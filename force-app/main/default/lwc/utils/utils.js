export class Utils {

    static validateElements(querySelectorCriteria) {
        const allValid = [...this.template.querySelectorAll(querySelectorCriteria)]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    static deadlineCheck(deadline) {
        let isDeadlineBird = false;

        let earlyBirdDeadline = Date.parse(deadline);
        let dateTimeNow = Date.now();

        if (earlyBirdDeadline >= dateTimeNow) {
            isDeadlineBird = true;
        }

        return isDeadlineBird;
    }

    static emailValidationRegex(email){
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

}
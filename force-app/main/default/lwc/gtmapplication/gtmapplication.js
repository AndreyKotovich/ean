import {LightningElement, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import getAccessToken from '@salesforce/apex/GTMGenerator.getAccessToken';
import getMeetings from '@salesforce/apex/GTMGenerator.getMeetings';
import createMeeting from '@salesforce/apex/GTMGenerator.createMeeting';
import deleteMeeting from '@salesforce/apex/GTMGenerator.deleteMeeting';
import getUsers from '@salesforce/apex/GTMGenerator.getUsers';
import getLicenses from '@salesforce/apex/GTMGenerator.getLicenses';
import createUserSCIM from '@salesforce/apex/GTMGenerator.createUserSCIM';
import createUser from '@salesforce/apex/GTMGenerator.createUser';
import getUserSCIM from '@salesforce/apex/GTMGenerator.getUserSCIM';
import setUserLicense from '@salesforce/apex/GTMGenerator.setUserLicense';
import getAccessTokenAnyUser from '@salesforce/apex/GTMGenerator.getAccessTokenAnyUser';
import updateUser from '@salesforce/apex/GTMGenerator.updateUser';
import getMyself from '@salesforce/apex/GTMGenerator.getMyself';
import createMeetingLogMeIn from '@salesforce/apex/GTMGenerator.createMeetingLogMeIn';
import deleteUserLicense from '@salesforce/apex/GTMGenerator.deleteUserLicense';
import deleteMeetingLogMeIn from '@salesforce/apex/GTMGenerator.deleteMeetingLogMeIn';
import updateMeetingLogMeIn from '@salesforce/apex/GTMGenerator.updateMeetingLogMeIn';
import sendEmailToParticipants from '@salesforce/apex/GTMGenerator.sendEmailToParticipants';
import checkUserProfile from '@salesforce/apex/GTMGenerator.checkUserProfile';
import startMeeting from '@salesforce/apex/GTMGenerator.startMeeting';
import getContactsId from '@salesforce/apex/GTMGenerator.getContactsId';
import getContactsData from '@salesforce/apex/GTMGenerator.getContactsData';


export default class Gtmapplication extends LightningElement {
    @track value = '';
    @track showMeetings = false;
    @track showCreate = false;
    @track hasNoMeetings;
    @track meetingsHistoryList = [];
    @track isCardForm = false;
    @track openmodel = false;
    @track showFinished = false;
    @track filterDate;
    @track newMeeting = {};
    @track defaultParticipants = [];
    @track externalParticipants = '';
    @track isMeetNow = false;

    @track loginData;
    @track users;
    @track error;
    @track matchedUser;
    // @track displayGTM = checkUserProfile();
    // @track displayGTM = this.connectedCallback();
    @track displayGTM = false;
    @track displayStartMeeting = true;

    goToMeetingParams = {};
    cId;
    cName;
    contactFirstName;
    contactLastName;
    contactEmail;
    contactPass;
    contactLogMeInEmail;
    license; // license key
    filterDateValue;
    manageLicenceData;

    userSCIMToCreate; // new created SCIM user
    createdUser; // new created user
    newUserCredentials;
    currentUser; // new created user credentials
    myself; // current user information
    createdMeeting; // new created meeting
    uniqueMeetingId; // unique Meeting Id from LogMeIn
    updateMeetingUniqueId; // Unique Id for updating meeting
    result; // Store result
    hostURL;
    meetingUniqueIdForStart; // Meeting unique id

    // usersSCIM = [];
    // startIndex = 1;
    // itemsPerPage = 0;
    // totalResults = 0;

    editMode = false;
    durationOptions = [
        {label: '15 min', value: 15},
        {label: '30 min', value: 30},
        {label: '45 min', value: 45},
        {label: '60 min', value: 60},
        {label: '1.5 h', value: 90},
        {label: '2 h', value: 120},
        {label: '2.5 h', value: 150},
        {label: '3 h', value: 180},
        {label: '4 h', value: 240},
        {label: '5 h', value: 300},
        {label: '6 h', value: 360},
        {label: '7 h', value: 420},
        {label: '8 h', value: 480},
    ];


    connectedCallback() {

        checkUserProfile()
            .then(res => {
                if(res) {
                    console.info('checkUserProfile result: ', res);
                    this.displayGTM = true;
                    this.getRelatedMeetings();
                    console.info('Session Storage: ', sessionStorage.getItem('selectedParticipants'));
                    if(sessionStorage.getItem('selectedParticipants')) {
                        console.info('Open new meeting with participants.');
                        this.openmodal();
                    }
                    // return true;
                } else {
                    this.displayGTM = false;
                    this.showToast('Error', 'You don\'t have access to GoToMeeting', 'error');
                    // return false;
                }
            })
            // .catch(error => {
            //     console.error('checkUserProfile_ERROR: '+ JSON.stringify(error));
            //     this.showToast('Error', 'Community contact does not exist and can not be created. '+
            //         'You can not use G2M.', 'error');
            //     // this.displayGTM = false;
            //     // return false;
            // });
    }


    filterMeetings() {
        console.log('filterMeetings');
        console.log(this.cId);
        if (this.cId != null) {
            this.meetingsHistoryList = [];
            if (this.fullMeetingHistory) {

                console.info('fullMeetingHistory: ', this.fullMeetingHistory);

                // Is display start meeting link
                if (this.fullMeetingHistory[0] &&
                    this.fullMeetingHistory[0].organizerName &&
                    this.fullMeetingHistory[0].organizerName === this.cName) {
                    this.displayStartMeeting = true;
                } else {
                    this.displayStartMeeting = false;
                }

                this.fullMeetingHistory.forEach(element => {
                    let endDate = new Date(element.endDate);
                    if (endDate >= this.filterDateValue) {
                        if (this.showFinished) {
                            this.meetingsHistoryList.push(element);
                        } else if (!element.isFinished) {
                            this.meetingsHistoryList.push(element);
                        }
                    }
                });
            }

            if (this.meetingsHistoryList.length > 0) {

                console.info('meetingsHistoryList: ', this.meetingsHistoryList);

                this.showMeetings = true;
                this.hasNoMeetings = false;
            } else {
                this.showMeetings = false;
                this.hasNoMeetings = true;
            }
        } else {
            this.showToast('Error', 'Community contact is not exist.', 'error');
        }

    }


    /**
     * GET User info and Related Meetings
     */
    getRelatedMeetings() {
        console.log('getRelatedMeetings');

        let today = new Date();
        let dd = today.getDate();
        let mm = today.getMonth() + 1;
        let yyyy = today.getFullYear();

        dd = dd < 10 ? '0' + dd : dd;
        mm = mm < 10 ? '0' + mm : mm;

        this.filterDate = yyyy + '-' + mm + '-' + dd;
        this.filterDateValue = new Date(this.filterDate);
        getMeetings()
            .then(result => {
                if (result) {
                    let response = JSON.parse(result);
                    console.info('User info and Related Meetings: ', response);
                    this.fullMeetingHistory = response.meetings;
                    if (response.cId.length > 0)
                    this.cId = response.cId[0];
                    this.cName = response.cName[0];
                    this.contactFirstName = response.contactFirstName[0];
                    this.contactLastName = response.contactLastName[0];
                    this.contactEmail = response.contactEmail[0];
                    this.contactPass = response.contactPass[0];
                    this.contactLogMeInEmail = response.contactLogMeInEmail[0];
                    // Is display start meeting link
                    if (this.fullMeetingHistory[0] &&
                        this.fullMeetingHistory[0].organizerName &&
                        this.fullMeetingHistory[0].organizerName === this.cName) {
                        this.displayStartMeeting = true;
                    } else {
                        this.displayStartMeeting = false;
                    }
                    this.filterMeetings();
                } else {
                }
            })
            .catch(error => {
                this.showToast('Error getting meetings', 'error');
                console.error(error);
            });
    }

    createNewMeeting() {
        console.info('createNewMeeting');
        console.info('cId: ', this.cId);
        console.info('cName: ', this.cName);

        // Null users list
        this.users = null;

        // Check start date time
        const stDate = new Date(this.newMeeting.startDate);
        const stTime = this.newMeeting.startTime;
        const stTimeArr = stTime.split(':');
        stDate.setHours(stTimeArr[0]);
        stDate.setMinutes(stTimeArr[1]);

        const miliisecStart = stDate.getTime();
        const miliisecNow = Date.now();

        if (this.cId != null) {
            if (this.newMeeting.subject.length < 1 || this.newMeeting.startDate == null
                || this.newMeeting.startTime == null || this.newMeeting.duration == null) {
                this.showToast('Error', 'Please, fill all required fields!', 'error');
            } else if(miliisecStart < miliisecNow) {
                this.showToast('Error', 'Check the date and time of the meeting.', 'error');
            } else {
                if (!this.newMeeting.participants.includes(this.cId))
                    this.newMeeting.participants.push(this.cId);
                console.info('New meeting: ',JSON.stringify(this.newMeeting));

                // Get AccessToken
                getAccessToken()
                    .then(result => {
                        console.info('result from CustomSettings response: ', result);
                        const response = JSON.parse(result);
                        this.accessToken = response.access_token;
                        this.accountKey = response.account_key;

                        this.loginData = {
                            accessToken : response.access_token,
                            accountKey : response.account_key
                        };
                        return this.loginData
                    })
                    .catch(error => {
                        this.showToast('Error getting Access Token', 'error');
                        console.error('Error getting Access Token: ', error);
                        throw new Error('Error getting Access Token');
                    })
                    .then(result => getUsers({data: result})
                    .then(result => {
                        // console.info('Result: ', JSON.parse(result));
                        console.info('Users Result: ', JSON.parse(result).results);
                        let users = JSON.parse(result).results;

                        // Set users to variable
                        this.users = users;
                        return users;
                    })
                    .catch(error => {
                        this.showToast('Error getting users from GTM', 'error');
                        console.error('Error getting users data: ', error);
                        throw new Error('Error getting users from GTM');
                    })
                    .then(result => {
                        let matched = null;

                        // Set email
                        let currentUserEmail = '';
                        if (this.contactLogMeInEmail) {
                            currentUserEmail = this.contactLogMeInEmail;
                        } else {
                            const email = this.contactEmail;
                            console.info('User email: ', email);
                            if(email.includes('@ean.org')) {
                                // if email contains @ean.org
                                console.info('email.includes(@ean.org). User email: ', email);
                                currentUserEmail = email;
                            } else {
                                // if not
                                console.info('email NOT includes(@ean.org). User email: ', email);
                                currentUserEmail = email.replace(/@/g,'.') + '@ean.org';
                            }
                        }

                        result.forEach(function (user) {
                            const userEmail = user.email;
                            if(userEmail === currentUserEmail) {
                                console.info('User matched: ', currentUserEmail);
                                matched = user;
                            }
                        });
                        // stored matched user or null
                        if(matched) {
                            this.matchedUser = matched;
                        } else {
                            this.matchedUser = null;
                        }
                        return getLicenses({data: this.loginData});
                    })
                    .then(result => {
                        console.info('Licenses: ', JSON.parse(result).results);
                        const licenses = JSON.parse(result).results;
                        // Set license
                        this.license = licenses[0];

                        if(licenses[0] && (licenses[0].seats > licenses[0].userCount)) {
                            this.showToast('Success',
                                'Licenses successfully received. License is valid.',
                                'success');
                            this.license = licenses[0];
                        } else {
                            this.showToast('Success',
                                'Licenses successfully received. No licenses available. Please wait or schedule an appointment.',
                                'error');
                            this.closeModal();
                        }
                        return result;
                    })
                    .catch(error => {
                        this.showToast('Error getting licenses', 'error');
                        console.error('Error getting licenses data: ', error);
                        throw new Error('Error getting licenses');
                    }))
                    .then(result=> {
                        if(this.matchedUser) {

                            // ***** User is exist in LogMeIn *****
                            console.info('User is exist on GTM.');

                            return this.userExist(null);
                        } else {

                            // ***** User is NOT exist in LogMeIn *****
                            console.info('User is not exist on GTM.');
                            if(this.contactEmail.indexOf('+') != -1) {
                                this.showToast('Error', 'Your email is not correct. You can not use "+" in email.'+
                                    'You can not use G2M with the current email.', 'error');
                                this.closeModal();
                            } else {
                                return this.userNotExist();
                            }
                        }
                    });
            }

        } else {
            this.showToast('Error', 'Community contact is not exist.', 'error');
            this.closeModal();
        }
    }


    /**
     * if user is exist in LogMeIn
     */
    userExist(newUser) {

        // Set user key and email
        let userKey = '';
        let userEmail = '';
        if (this.matchedUser && this.matchedUser.key) {
            if (this.matchedUser.key) {
                userKey = this.matchedUser.key;
                console.info('Matched user key: ', userKey);
            }
            if (this.matchedUser.email) {
                userEmail = this.matchedUser.email;
                console.info('Matched user email: ', userEmail);
            }
        } else if (newUser[0]) {
            if (newUser[0].key) {
                userKey = newUser[0].key;
                console.info('Created user key: ', userKey);
            }
            if (newUser[0].email) {
                userEmail = newUser[0].email;
                console.info('Created user email: ', userEmail);
            }
        }

            const data = {
                'userKey': userKey,
                'accessToken': this.loginData.accessToken,
                'accountKey': this.loginData.accountKey,
                'userEmail': userEmail,
                'licenceKey': this.license.key
            };
            console.info('setUserLicense data: ', data);
            // Storage the data
            this.manageLicenceData = data;

            // Set license for current user
            setUserLicense({data: data})
            .then(result=> {
                console.info('Set User License Successfully.');
                return result;
            })
            .catch(error=> {
                console.error('ERROR set User License: ', error);
                throw new Error('Set User License Error');
            })
            .then(result=> {
                // Set data
                let email = '';
                if (this.contactLogMeInEmail) {
                    email = this.contactLogMeInEmail;
                } else {
                    email = userEmail;
                }
                const accessData = {
                        'userEmail': email,
                        'userPass': this.contactPass
                    };
                console.info('Data for getAccessTokenAnyUser: ', accessData);
                // Activate User
                return getAccessTokenAnyUser({data: accessData});
            })
            .then(result=> {
                const myAuthenticationData = JSON.parse(result);

                // save current user
                this.currentUser = myAuthenticationData;
                console.info('getAccessTokenAnyUser: ', myAuthenticationData);
                // If another user is exist on LogMeIn server with same username
                if (myAuthenticationData.request_error) {
                    this.deleteLicenceFromUser(this.manageLicenceData);
                    this.closeModal();
                    this.showToast('Error', 'LogMeIn User conflict. Another user is exist on LogMeIn server with same username', 'error');
                    throw new Error('LogMeIn User conflict.');
                }
                return myAuthenticationData;
            })
            .catch(error=> {
                console.info('ERROR getAccessTokenAnyUser: ', error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                return Promise.reject();
            })
            .then(result=> {
                const data = {
                    'accountKey': result.account_key,
                    'accessToken': result.access_token
                };

                // GET Myself
                return getMyself({data: data});
            })
            .then(result=> {
                const myselfInfo = JSON.parse(result);
                this.myself = myselfInfo;
                console.info('Myself: ', myselfInfo);
                return myselfInfo;
            })
            .catch(error=> {
                console.error('ERROR Myself: ', error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                return Promise.reject();
            })
            .then(result=> {
                const data = {
                    'params': JSON.stringify(this.newMeeting),
                    'accessToken': this.currentUser.access_token,
                    'meetingUniqueId': this.updateMeetingUniqueId
                };
                console.info('data for create meeting: ', data);

                if (this.updateMeetingUniqueId) {
                    // Update meeting on server
                    console.info('updating meeting');
                    const updateData = {
                        'params': JSON.stringify(this.newMeeting),
                        // 'accessToken': this.loginData.accessToken,
                        'accessToken': this.currentUser.access_token,
                        'meetingUniqueId': this.updateMeetingUniqueId
                    };
                    console.info('data for updating meeting: ', updateData);
                    this.updateMeeting(updateData);
                }
                else {
                    // Create meeting on server
                    console.info('creating meeting');
                    return createMeetingLogMeIn({data: data});
                }
            })

            // GET link for start meeting
            .then(result=> {
                // Save to result variable
                this.result = result;

                // reset this.updateMeetingUniqueId
                this.updateMeetingUniqueId = null;

                let meeting = null;
                let meetingId = null;

                if (result) {
                    meeting = JSON.parse(result);
                    console.info('Result from createMeetingLogMeIn: ', meeting);
                    if (meeting[0]) {
                        meetingId = meeting[0].uniqueMeetingId;
                    } else {
                        console.error('Error. uniqueMeetingId is not exist.');
                        this.deleteLicenceFromUser(this.manageLicenceData);
                    }
                }

                // Set data for getting start meeting link
                const getStartMeetingData = {
                    'meetingId' : String(meetingId),
                    'accessToken' : this.currentUser.access_token
                };
                console.info('Data for getting start meeting link ', getStartMeetingData);
                return startMeeting({data: getStartMeetingData});
            })
            .catch(error=> {
                console.error(error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                throw new Error('Creating meeting error.');
            })
            // Set start meeting link to meeting
            .then(result=> {
                console.info('result.hostURL: ', JSON.parse(result).hostURL);
                console.info('result: ', JSON.parse(result));
                this.hostURL = JSON.parse(result).hostURL;
                return this.result;
            })
            .catch(error=> {
                console.error(error);
                throw new Error('Getting start meeting hostURL error.');
            })

            .then(result=> {

                // reset this.updateMeetingUniqueId
                this.updateMeetingUniqueId = null;

                let newMeeting = null;
                if (result) {
                    newMeeting = JSON.parse(result);
                    console.info('createMeetingLogMeIn result: ', result);
                    console.info('createMeetingLogMeIn newMeeting: ', newMeeting);
                    if (newMeeting[0]) {
                        this.createdMeeting = newMeeting[0];
                    }
                }

                console.info('create/update Meeting LogMeIn Success: ', newMeeting);
                return newMeeting;
            })
            .catch(error=> {
                console.error('Getting start meeting hostURL error: ', error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                throw new Error('Getting start meeting hostURL error.');
            })
            .then(result=> {
                // Set meeting details
                let uniqueMeetingId = '';
                let joinURL = '';
                if (result[0].joinURL) {
                    joinURL = result[0].joinURL;
                }
                if (result[0].uniqueMeetingId) {
                    uniqueMeetingId = result[0].uniqueMeetingId;
                }
                // Add data for create meeting in SF
                let ownerKey = null;
                if(this.myself && this.myself.key) {
                    ownerKey = this.myself.key;
                }
                const data = {
                    'params': JSON.stringify(this.newMeeting),
                    'uniqueMeetingId': uniqueMeetingId,
                    'joinURL': joinURL,
                    'hostURL': this.hostURL,
                    'ownerKey' : ownerKey
                };
                console.info('data for create meeting in SF: ', data);

                // Create Meeting on Salesforce
                return createMeeting({data: data});
            })
            .catch(error=> {
                console.error('New meeting translating error: ', error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                throw new Error('New meeting translating error.');
            })

            // Show toast and close modal
            .then(result=> {
                if (result) {
                    let message = 'Your ' + this.newMeeting.subject + ' is';
                    message += this.editMode === false ? ' created!' : ' updated!';
                    this.editMode = false;
                    let response = JSON.parse(result);
                        this.fullMeetingHistory = response.meetings;
                    this.showToast('Success', message, 'success');
                    this.filterMeetings();
                    this.closeModal();
                } else {
                    console.error('Error in Apex createMeeting method.');
                    this.deleteLicenceFromUser(this.manageLicenceData);
                }
                return result;
            })
            .catch(error=> {
                console.error(error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                throw new Error('Creating meeting in Salesforce error.');
            })

            // Delete user license
            .then(result=> {
                // User key
                let userKey = null;
                if (this.myself && this.myself.key) {
                    userKey = this.myself.key;
                } else if (this.matchedUser && this.matchedUser.key) {
                    userKey = this.matchedUser.key;
                }
                const dataForDelete = {
                    'accessToken': this.loginData.accessToken,
                    'accountKey': this.currentUser.account_key,
                    'licenceKey': this.license.key,
                    'userKey': userKey
                };
                console.info('Data for license delete: ', dataForDelete);

                // Delete user license
                return deleteUserLicense({data: dataForDelete});
            })
            .then(result=> {
                console.info('License successfully deleted.', result);
                return result;
            })
            .catch(error=> {
                console.error('Error license delete.', error);
                // this.showToast('Error', 'Error license delete. Inform system administrator.', 'error');
                throw new Error('Error deleting licence from user.');
            })
            .then(result=> {
                const participants = this.newMeeting.participants;
                let participantsString = '';
                participants.forEach(function (part) {
                    participantsString += part+',';
                });
                // remove the last ','
                participantsString = (participantsString.substring(0, participantsString.length - 1));
                console.info('participantsString: ', participantsString);
                let joinURL = '';
                if (this.createdMeeting) {
                    joinURL = this.createdMeeting.joinURL;
                } else {
                    throw new Error('A meeting is not created.')
                }
                // Get external URL
                let externalURL = '';
                if (this.newMeeting && this.newMeeting.externalParticipants) {
                    externalURL = this.newMeeting.externalParticipants;
                }
                // Get meeting subject
                let meetingName = '';
                if (this.newMeeting && this.newMeeting.subject) {
                    meetingName = this.newMeeting.subject;
                }
                // Get duration
                let duration = '';
                if (this.newMeeting && this.newMeeting.duration) {
                    duration = this.newMeeting.duration;
                }
                // Start date string for email
                let fullStartDateTime = null;
                let startDateTimeToInviteMethod = '';
                let stDate = '';
                let meetingDate = '';
                let startDate = '';
                let startTime = '';
                let endTime = '';
                if (this.newMeeting && this.newMeeting.startDate) {
                    stDate = new Date(this.newMeeting.startDate);
                    if (this.newMeeting && this.newMeeting.startTime) {
                        const arr = this.newMeeting.startTime.split(':');
                        fullStartDateTime = stDate.setHours(Number(arr[0]), Number(arr[1]));
                        fullStartDateTime = new Date(fullStartDateTime);
                        console.info('stDate: ', fullStartDateTime);

                        startDateTimeToInviteMethod = fullStartDateTime.getFullYear().toString() +','+
                            (fullStartDateTime.getMonth()+1).toString() +','+
                            fullStartDateTime.getDate().toString() +','+
                            fullStartDateTime.getHours().toString() +','+
                            fullStartDateTime.getMinutes().toString() +',00';
                        console.info('startDateTimeToInviteMethod: ', startDateTimeToInviteMethod);

                        startTime = this.getTimeString(fullStartDateTime.getHours()) + ':' +
                            this.getTimeString(fullStartDateTime.getMinutes());
                        // Add duration to receive end time
                        const endStartDateTime = new Date(fullStartDateTime.getTime() + duration*60000);
                        endTime = this.getTimeString(endStartDateTime.getHours()) + ':' +
                            this.getTimeString(endStartDateTime.getMinutes());
                    }

                    const stYear = stDate.getFullYear().toString();
                    const stMonth = this.getMonthByNumber(stDate.getMonth());
                    const stDay = stDate.getDate().toString();

                    meetingDate = stMonth +' '+ stDay +', '+ stYear;
                }
                // Add date to start meeting string
                if (meetingDate) {
                    startDate = meetingDate;
                }
                // Add time to start meeting string
                if (startTime && endTime) {
                    startDate += ' at '+ startTime + ' - '+ endTime + ' (UTC+01:00)';
                }
                console.info('startDate: ', startDate);

                // Send email to participants
                const sendData = {
                    'participantsString': participantsString,
                    'externalURL' : externalURL,
                    'joinURL': joinURL,
                    'ownerId' : this.cId,
                    'meetingName': meetingName,
                    'meetingTime': startTime,
                    'startDate': startDate,
                    'startDateTimeToInviteMethod': startDateTimeToInviteMethod,
                    'meetingDuration': duration
                };
                console.info('Data for send email: ', sendData);
                if (this.createdMeeting) {
                    return sendEmailToParticipants({data: sendData})
                } else {
                    return Promise.reject();
                }
            })
            .then(result=> {
                console.info('From send email: ', result);
            })
            .catch(error=> {
                console.error('Error send email: ', error);
                throw new Error('Error sending email.');
            });
    };

    /**
     * Get Month by value
     * @param val
     * @returns {string}
     */
    getMonthByNumber(val) {
        switch (val) {
            case 0: return 'Jan';
            case 1: return 'Feb';
            case 2: return 'Mar';
            case 3: return 'Apr';
            case 4: return 'May';
            case 5: return 'Jun';
            case 6: return 'Jul';
            case 7: return 'Aug';
            case 8: return 'Sep';
            case 9: return 'Oct';
            case 10: return 'Nov';
            case 11: return 'Dec';
        }
    };

    /**
     * Get Hours and Minutes
     * @param val
     * @returns {string}
     */
    getTimeString(val) {
        if (val < 10) {
            val = '0' + val.toString();
        } else {
            val = val.toString();
        }
        return val;
    }

    /**
     * if user is not exist in LogMeIn
     */
    userNotExist() {
        // let startIndex = 1;
        // let itemsPerPage = 0;
        // let totalResults = 0;

        // Set email
        let userMail = '';
        if (this.contactLogMeInEmail) {
            userMail = this.contactLogMeInEmail;
        } else {
            const email = this.contactEmail;
            console.info('User email: ', email);
            if(email.includes('@ean.org')) {
                // if email contains @ean.org
                console.info('Email includes @ean.org. User email: ', email);
                userMail = email;
            } else {
                // if not
                console.info('Email NOT includes @ean.org. User email: ', email);
                userMail = email.replace(/@/g,'.') + '@ean.org';
            }
        }
        console.info('User email from SF: ', userMail);
        let isSCIMUserNotExist = false;
        let userSCIM = null;

        const getUserSCIMdata = {
            'accessToken': this.loginData.accessToken,
            'userName': userMail
        };
        console.info('getUserSCIMdata: ', getUserSCIMdata);
        getUserSCIM({data: getUserSCIMdata})
        .then(result=> {
            // Result
            const res = JSON.parse(result);
            // Users
            const resultSCIM = res.resources;
            console.info('getUserSCIM result: ', res);
            console.info('getUserSCIM Users: ', resultSCIM);
            
            if(res.totalResults > 0) {
                resultSCIM.forEach(function (user) {
                    if(user.userName === userMail) {
                        console.info('Email matched: ', userMail);
                        isSCIMUserNotExist = true;
                        userSCIM = user;
                    } else {
                        isSCIMUserNotExist = false;
                    }
                })
            } else {
                isSCIMUserNotExist = false;
            }
            if(isSCIMUserNotExist) {
                return this.SCIMUserExist(userSCIM);
            } else {
                return this.SCIMUserNotExist();
            }
        })
        .catch(error=> {
            console.info('getUserSCIM error: ', error);
        })
    };


    /**
     * if user is exist in organization (SCIM)
     * @param userSCIM
     * @constructor
     */
    SCIMUserExist(userSCIM) {
        console.info('SCIMUserExist: ', userSCIM);
        const userToCreate = {
            'accountKey': this.accountKey,
            'accessToken': this.loginData.accessToken,
            'userFirstName': userSCIM.name.givenName,
            'userLastName': userSCIM.name.familyName,
            'userPass': this.contactPass,
            'userEmail': userSCIM.userName,
            'license': this.license.key
        };
        createUser({data: userToCreate})
            .then(result=> {
                const createdUser = JSON.parse(result);
                console.info('User created successfully.', createdUser);
                this.createdUser = createdUser;
                return createdUser;
            })
            .catch(error=> {
                this.showToast('Error creating user', 'error');
                console.error('Error creating user: ', error);
            })
            .then(result=> {

                // Now the user is created.
                return this.userExist(result);
            });
    };


    /**
     * if user is not exist in organization (SCIM)
     * 
     */
    SCIMUserNotExist() {
        // create user data for create SCIM User
        // change email for translate it to SCIM
        let userEmail = '';
        let userLogMeInEmail = '';
        console.info('contactEmail: ', this.contactEmail);

        if(this.contactEmail.includes('@ean.org')) {
            console.info('contactEmail.includes(@ean.org): ', this.contactEmail);
            userEmail = this.contactEmail.replace(/@ean.org/g, '');
            userLogMeInEmail = this.contactEmail;
        } else {
            console.info('contactEmail NOT includes(@ean.org): ', this.contactEmail);
            userEmail = this.contactEmail.replace(/@/g,'.');
            userLogMeInEmail = userEmail+'@ean.org';
        }
        // const userEmail = this.contactEmail.replace(/@/g,'.');
        // const userLogMeInEmail = userEmail+'@ean.org';

        // create password for user
        const pass = this.contactPass ? this.contactPass : Math.round(Math.random() * 1000000000);
        const userSCIMToCreate = {
            'accessToken': this.loginData.accessToken,
            'userName': this.cName,
            'userFirstName': this.contactFirstName,
            'userLastName': this.contactLastName,
            'userPass': pass,
            'userEmail': userEmail
        };
        const updateUserData = {
            'userPass': pass,
            'userLogMeInEmail': userLogMeInEmail,
            'userEmail': this.contactEmail
        };
        console.info('updateUserData : ', updateUserData);
        this.newUserCredentials = updateUserData;
        updateUser({data: updateUserData});

        this.userSCIMToCreate = userSCIMToCreate;
        console.info('userSCIMToCreate Data: ', userSCIMToCreate);
        createUserSCIM({data: userSCIMToCreate})
            .then(result=> {
                console.info('result Data: ', result);
                const createdSCIMUser = JSON.parse(result);
                console.info('User SCIM created successfully.', createdSCIMUser);
                this.createdUser = createdSCIMUser;
                return createdSCIMUser;
            })
            .catch(error=> {
                this.showToast('Error creating SCIM user', 'error');
                console.error('Error SCIM creating user: ', error);
            })
            .then(result=> {
                const userToCreate = {
                    'accountKey': this.accountKey,
                    'accessToken': this.loginData.accessToken,
                    'userFirstName': result.name.givenName,
                    'userLastName': result.name.familyName,
                    'userPass': this.userSCIMToCreate.userPass,
                    'userEmail': result.userName,
                    'license': this.license.key
                };
                return createUser({data: userToCreate});
            })
            .then(result=> {
                this.showToast('Success', 'User in LogMeIn created successfully!', 'success');
                const createdUser = JSON.parse(result);
                console.info('User in LogMeIn created successfully.', createdUser);
                this.createdUser = createdUser;
                return createdUser;
            })
            .catch(error=> {
                this.showToast('Error creating LogMeIn user', error, 'error');
                console.error('Error creating user: ', error);
            })
            .then(result=> {

                // Now the user is created.
                this.contactPass = this.userSCIMToCreate.userPass;

                return this.userExist(result);
            });
    };

    /**
     * Delete the licence from any user
    //  * @param {String} acToken 
    //  * @param {String} accKey 
    //  * @param {String} licKey 
    //  * @param {String} usKey 
        * @param {Object} deleteLicenceData
     */
    deleteLicenceFromUser(deleteLicenceData) {
        // const deleteLicenceData = {
        //     'accessToken': acToken,
        //     'accountKey': accKey,
        //     'licenceKey': licKey,
        //     'userKey': usKey
        // };
        // console.info('Data for license delete: ', deleteLicenceData);

        // Delete user license
        deleteUserLicense({data: deleteLicenceData})
        .then(result => {
            console.info('License successfully deleted.', result);
        })
        .catch(error=> {
            console.error('Error license delete.', error);
            throw new Error('Error deleting licence from user.');
        });
    };


    editMeeting(meetingId) {
        console.log('editMeeting');
        console.log(this.cId);

        // Get unique meeting Id
        let meetings = this.meetingsHistoryList;
        let uniqueId = '';

        let startDate, startTime;

        meetings.forEach(function (meeting) {
            if (meeting.index === meetingId) {
                uniqueId = meeting.uniqueMeetingId;
                startDate = meeting.startDate;
                startTime = meeting.startTime;
            }
        });
        console.info('uniqueId: ', uniqueId);
        this.updateMeetingUniqueId = uniqueId;

        let dt = new Date(startDate);
        let startTimeArr = startTime.split(':');

        dt.setHours(startTimeArr[0]);
        const miliisecNow = Date.now();
        const miliisecStart = dt.getTime();

        if(miliisecNow > miliisecStart - 30*60000) {
            console.info('This meeting cannot be edited.');
            this.showToast('Error', 'This meeting cannot be edited. It is being processed. Create a new meeting.', 'error');
        } else {
            if (this.cId != null) {
                this.defaultParticipants = [];
                for (let i = 0; i < this.meetingsHistoryList.length; i++) {
                    if (this.meetingsHistoryList[i].index === meetingId) {
                        let meetingToEdit = this.meetingsHistoryList[i];
                        this.newMeeting.subject = meetingToEdit.subject;
                        this.newMeeting.description = meetingToEdit.description;
                        this.newMeeting.startTime = meetingToEdit.startTime;
                        this.newMeeting.startDate = meetingToEdit.startDate;
                        this.newMeeting.index = meetingToEdit.index;
                        this.newMeeting.duration = meetingToEdit.duration;
                        this.defaultParticipants = meetingToEdit.participantList;
                        // this.externalParticipants = meetingToEdit.externalParticipants;
                        this.newMeeting.participants = [];
                        this.newMeeting.externalParticipants = meetingToEdit.externalParticipants;
                        meetingToEdit.participantList.forEach(element => {
                            this.newMeeting.participants.push(element.recId);
                        });
    
                        let today = new Date();
                        let dd = today.getDate();
                        let mm = today.getMonth() + 1;
                        let yyyy = today.getFullYear();
                        dd = dd < 10 ? '0' + dd : dd;
                        mm = mm < 10 ? '0' + mm : mm;
    
                        this.newMeeting.todaysDate = yyyy + '-' + mm + '-' + dd;
                        break;
                    }
                }
                this.editMode = true;
                this.openmodal();
    
            } else {
                this.showToast('Error', 'Community contact is not exist.', 'error');
            }
        }
    }

    deleteMeeting(meetingId) {
        console.log('deleteMeeting');
        console.log(this.cId);
        console.info('meetingId: ', meetingId);

        // Get unique meeting Id
        let meetings = this.meetingsHistoryList;
        let uniqueId = '';

        let startDate, startTime;

        meetings.forEach(function (meeting) {
            if (meeting.index === meetingId) {
                uniqueId = meeting.uniqueMeetingId;
                startDate = meeting.startDate;
                startTime = meeting.startTime;
            }
        });
        console.info('uniqueId: ', uniqueId);

        let dt = new Date(startDate);
        let startTimeArr = startTime.split(':');

        dt.setHours(startTimeArr[0]);
        const miliisecNow = Date.now();
        const miliisecStart = dt.getTime();

        if(miliisecNow > miliisecStart - 30*60000) {
            console.info('This meeting cannot be deleted.');
            this.showToast('Error', 'This meeting cannot be deleted. It is being processed.', 'error');
        } else {
            if (this.cId != null) {

                //Login current User
                const userLoginData = {
                    'userEmail': this.contactLogMeInEmail,
                    'userPass': this.contactPass
                };
                console.info('login Data: ', userLoginData);
    
                getAccessTokenAnyUser({data: userLoginData})
                    .then(result=> {
                        const authenticationData = JSON.parse(result);
    
                        // save current user
                        this.currentUser = authenticationData;
                        console.info('getAccessTokenAnyUser: ', authenticationData);
                        return authenticationData;
                    })
                    .catch(error=> {
                        console.error('Login user ERROR: ', error);
                    })
                    .then(result=> {
                        const data = {
                            'accountKey': result.account_key,
                            'accessToken': result.access_token
                        };
    
                        // GET Myself
                        return getMyself({data: data});
                    })
                    .then(result=> {
                        const myselfInfo = JSON.parse(result);
    
                        // Save mine data to variable
                        this.myself = myselfInfo;
                        console.info('Myself: ', myselfInfo);
                        return myselfInfo;
                    })
                    .catch(error=> {
                        console.error('ERROR Myself: ', error);
                    })
                    .then(result=> {
                        const uniqueIdData = {
                            'uniqueId': uniqueId,
                            'accessToken': this.currentUser.access_token
                        };
                        console.info('Data for delete meeting from LogMeIn: ', uniqueIdData);
    
                        // Delete meeting from server
                        return deleteMeetingLogMeIn({data: uniqueIdData});
                    })
                    .then(result=> {
                        console.info('Meeting delete successful.', result);
    
                        // Delete meeting from Salesforce
                        return deleteMeeting({meetingId: meetingId});
                    })
                    .catch(error=> {
                        console.error('ERROR Meeting delete: ', error);
                    })
                    .then(result => {
                        if (result) {
                            let response = JSON.parse(result);
                            this.fullMeetingHistory = [];
                            this.fullMeetingHistory = response.meetings;
                            this.showToast('Success', 'Meeting is deleted', 'success');
                            this.filterMeetings();
                        } else {
                        }
                    })
                    .catch(error => {
                        this.showToast('Error deleting meeting', error.body.message, 'error');
                        console.log(error);
                    });
            } else {
                this.showToast('Error', 'Community contact is not exist.', 'error');
            }
        }
    }


    //HANDLERS for input fields START ===>
    handleInputFilterDate(event) {
        console.log('handleInputDate');
        this.filterDate = event.target.value;
        this.filterDateValue = new Date(this.filterDate);
        this.filterMeetings();

    }

    handleInputFilterCheck(event) {
        console.log('handleInputCheck');
        this.showFinished = event.target.checked;
        this.filterMeetings();
    }

    handleInputMeetingSub(event) {
        this.newMeeting.subject = event.target.value;
        console.log('handleInputMeetingSub: ', this.newMeeting.subject);
    }

    handleInputMeetingDate(event) {
        this.newMeeting.startDate = event.target.value;
        console.log('handleInputMeetingDate: ', this.newMeeting.startDate);
    }

    handleInputMeetingTime(event) {
        this.newMeeting.startTime = event.target.value;
        console.log('handleInputMeetingTime: ', this.newMeeting.startTime);
    }

    handleInputMeetingDuration(event) {
        let value = event.target.value;
        this.newMeeting.duration = parseInt(value);
        console.log('handleInputMeetingDuration: ', this.newMeeting.duration);
    }

    handlerInputMeetingDesc(event) {
        console.log('handlerInputMeetingDesc');
        this.newMeeting.description = event.detail.value;
    }

    handlerInputMeetingExternalParticipants(event) {
        console.log('handlerInputMeetingExternalParticipants');
        this.newMeeting.externalParticipants = event.detail.value;
        let space = /\s+/gi;
        let comma = /,+/gi;
        let external = '';
        if (this.newMeeting && this.newMeeting.externalParticipants) {
            external = this.newMeeting.externalParticipants;
            external = external.replace(space, '');
            external = external.replace(':', ',');
            external = external.replace(';', ',');
            external = external.replace(comma, ',');
            this.newMeeting.externalParticipants = external;
            console.info(this.newMeeting.externalParticipants);
        }
    }

    handlerLookupChange(event) {
        console.log('handlerLookupChange');
        this.newMeeting.participants = [];
        let details = event.detail;
        if (details.hasOwnProperty('selRecords')) {
            details.selRecords.forEach(element => {
                let contactId = element.recId;
                if (contactId != null) {
                    this.newMeeting.participants.push(contactId);
                }
            });
            if (!this.newMeeting.participants.includes(this.cId))
                this.newMeeting.participants.push(this.cId);
            console.info('participants: ', JSON.stringify(this.newMeeting.participants));
            console.info('participants length: ', this.newMeeting.participants.length);
            if (this.newMeeting.participants.length > 1) {
                this.isMeetNow = true;
            } else {
                this.isMeetNow = false;
            }
        }
    }

    handlerEditDeleteMeeting(event) {
        console.log('handlerEditDeleteMeeting');
        let mode = event.detail.value;
        let meetingId = event.currentTarget.dataset.meetingid;
        console.info('Click Delete: ', event.currentTarget.dataset.meetingid);
        if (mode === 'edit') {
            this.editMeeting(meetingId);
        } else {
            this.deleteMeeting(meetingId);
        }
    }

    //<=== HANDLERS END

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    /**
     * Set current date and time for "Meet Now"
     * and for autocomplete opened "New Meeting" form
     */
    setCurrentDateTime() {
        let today = new Date();
        let dd = today.getDate();
        let mm = today.getMonth() + 1;
        const yyyy = today.getFullYear();
        let MM = today.getMinutes();
        let HH = today.getHours();
        dd = dd < 10 ? '0' + dd : dd;
        mm = mm < 10 ? '0' + mm : mm;
        HH = HH < 10 ? '0' + HH : HH;
        MM = MM < 10 ? '0' + MM : MM;
        const filterDate = yyyy + '-' + mm + '-' + dd;
        this.newMeeting.startDate = filterDate;
        this.newMeeting.todaysDate = filterDate;
        this.newMeeting.startTime = HH + ':' + MM;
    }

    //FUNCTIONS for modal START ===>
    openmodal() {
        console.log('openModal');
        if (!this.editMode) {
            let defPartArr = [];
            const sessStorage = sessionStorage.getItem('selectedParticipants');
            if(sessStorage) {
                // defPartArr = JSON.parse(sessStorage);
                // JSON.parse(sessStorage).forEach(function(item) {
                //     console.info('item: ', item);
                // })
                const data = {'listIds': sessStorage};
                getContactsId({data: data})
                .then(res => {
                    console.info('getContactsIds result: ', res);
                    const data = {'ids': res}
                    return getContactsData({data: data});
                })
                .catch(error => {
                    console.info('getContactsName error: ', error);
                })
                .then(res => {
                    console.info('getContactsData result: ', res);
                    defPartArr = JSON.parse(res);
                    this.defaultParticipants = defPartArr ? defPartArr : [];
                    this.newMeeting = {
                        subject: '',
                        startDate: '',
                        startTime: '',
                        duration: 30,
                        todaysDate: '',
                        description: '',
                        participants: []
                    };
                    this.setCurrentDateTime();
                });
            } else {
                this.defaultParticipants = defPartArr ? defPartArr : [];
                this.newMeeting = {
                    subject: '',
                    startDate: '',
                    startTime: '',
                    duration: 30,
                    todaysDate: '',
                    description: '',
                    participants: []
                };
                this.setCurrentDateTime();
            }
        }
        console.log(JSON.stringify(this.newMeeting));
        this.openmodel = true;
    }

    closeModal() {
        this.openmodel = false;
        this.editMode = false;
    }

    /**
     * Create a fast new meeting
     */
    addMeetNow() {
        console.info('Meet Now click');
        console.info('cId: ', this.cId);
        if (this.cId != null) {
            if (this.newMeeting.duration === null) {
                this.showToast('Error', 'Please, fill all required fields!', 'error');
            } else {
                if (!this.newMeeting.participants.includes(this.cId))
                    this.newMeeting.participants.push(this.cId);
                console.log('new Meeting detail: ', JSON.stringify(this.newMeeting));

                this.setCurrentDateTime();

                // Get AccessToken
                getAccessToken()
                    .then(result => {
                        console.info('result from CustomSettings response: ', result);
                        const response = JSON.parse(result);
                        this.accessToken = response.access_token;
                        this.accountKey = response.account_key;

                        this.loginData = {
                            accessToken : response.access_token,
                            accountKey : response.account_key
                        };
                        return this.loginData
                    })
                    .catch(error => {
                        this.showToast('Error getting Access Token', 'error');
                        console.error('Error getting Access Token: ', error);
                        throw new Error('Error getting Access Token');
                    })
                    .then(result => getUsers({data: result})
                        .then(result => {
                            console.info('Users Result: ', JSON.parse(result).results);
                            let users = JSON.parse(result).results;

                            // Set users to variable
                            this.users = users;
                            return users;
                        })
                        .catch(error => {
                            this.showToast('Error getting users from GTM', 'error');
                            console.error('Error getting users data: ', error);
                            throw new Error('Error getting users from GTM');
                        })
                        .then(result => {
                            let matched = null;

                            // const currentUserEmail = this.contactLogMeInEmail;
                            // Set email
                            let currentUserEmail = '';
                            if (this.contactLogMeInEmail) {
                                currentUserEmail = this.contactLogMeInEmail;
                            } else {
                                const email = this.contactEmail;
                                console.info('User email: ', email);
                                if(email.includes('@ean.org')) {
                                    // if email contains @ean.org
                                    console.info('email.includes(@ean.org). User email: ', email);
                                    currentUserEmail = email;
                                } else {
                                    // if not
                                    console.info('email NOT includes(@ean.org). User email: ', email);
                                    currentUserEmail = email.replace(/@/g,'.') + '@ean.org';
                                }
                            }

                            result.forEach(function (user) {
                                const userEmail = user.email;
                                if(userEmail === currentUserEmail) {
                                    console.info('User matched: ', currentUserEmail);
                                    matched = user;
                                }
                            });
                            // stored matched user or null
                            if(matched) {
                                this.matchedUser = matched;
                            } else {
                                this.matchedUser = null;
                            }
                            return getLicenses({data: this.loginData});
                        })
                        .then(result => {
                            console.info('Licenses: ', JSON.parse(result).results);
                            const licenses = JSON.parse(result).results;
                            // Set license
                            this.license = licenses[0];

                            if(licenses[0] && (licenses[0].seats > licenses[0].userCount)) {
                                this.showToast('Success',
                                    'Licenses successfully received. License is valid.',
                                    'success');
                                this.license = licenses[0];
                            } else {
                                this.showToast('Success',
                                    'Licenses successfully received. License is not activate.',
                                    'error');
                                this.closeModal();
                            }
                            return result;
                        })
                        .catch(error => {
                            this.showToast('Error getting licenses', 'error');
                            console.error('Error getting licenses data: ', error);
                            throw new Error('Error getting licenses');
                        }))
                    .then(result=> {
                        if(this.matchedUser) {

                            // ***** User is exist in LogMeIn *****
                            console.info('User is exist on GTM.');

                            return this.userExist(null);
                        } else {

                            // ***** User is NOT exist in LogMeIn *****
                            console.info('User is not exist on GTM.');
                            if(this.contactEmail.indexOf('+') != -1) {
                                this.showToast('Error', 'Your email is not correct. You can not use "+" in email.'+
                                    'You can not use G2M.', 'error');
                                this.closeModal();
                            } else {
                                return this.userNotExist();
                            }
                        }
                    });
            }

        } else {
            this.showToast('Error', 'Community contact is not exist.', 'error');
        }
    }


    /**
     * Update meeting
     * @param data
     */
    updateMeeting(data) {
        console.log('updateMeeting');
        updateMeetingLogMeIn({data: data})
            .then(result=> {
                console.info('Meeting updated');
            })
            .catch(error=> {
                console.error('Error updating meeting');
            })
            .then(result=> {

                // reset this.updateMeetingUniqueId
                this.updateMeetingUniqueId = null;

                let newMeeting = null;
                if (result) {
                    newMeeting = JSON.parse(result);
                    this.createdMeeting = newMeeting[0];
                }

                console.info('createMeetingLogMeIn Success: ', newMeeting);
                return newMeeting;
            })
            .catch(error=> {
                console.error('ERROR createMeetingLogMeIn: ', error);
            })
            .then(result=> {
                const data = {
                    'params': JSON.stringify(this.newMeeting),
                    'uniqueMeetingId': null,
                    'joinURL': null
                };

                // Create Meeting on Salesforce
                return createMeeting({data: data});
            })
            .then(result=> {
                if (result) {
                    let message = 'Your ' + this.newMeeting.subject + ' is';
                    message += this.editMode === false ? ' created!' : ' updated!';
                    this.editMode = false;
                    let response = JSON.parse(result);
                    this.fullMeetingHistory = response.meetings;
                    this.showToast('Success', message, 'success');
                    this.filterMeetings();
                    this.closeModal();
                } else {
                    console.error('Error in Apex createMeeting method.');
                }
                return result;
            })
            .catch(error=> {
                this.showToast('Error', error.body, 'error');
                console.error(JSON.stringify(error));
            })
            .then(result=> {
                const dataForDelete = {
                    'accessToken': this.currentUser.access_token,
                    'accountKey': this.currentUser.account_key,
                    'licenceKey': this.license.key,
                    'userKey': this.myself.key
                };
                console.info('Data for license delete: ', dataForDelete);

                // Delete user license
                return deleteUserLicense({data: dataForDelete});
            })
            .then(result=> {
                console.info('License successfully deleted.');
            })
            .catch(error=> {
                console.error('Error license delete.', error);
            });
    }

    /**
     * Start meeting if you are owner
     */
    startMeeting(event) {
        console.info('Start Meeting');
        let meetingId = event.currentTarget.dataset.meetingid;
        console.info('Meeting Salesforce Id : ', meetingId);
        console.info('User cId: ', this.cId);

        // Get unique meeting Id
        let meetings = this.meetingsHistoryList;
        let uniqueId = '';

        let startDate, startTime, endDate, endTime;

        meetings.forEach(function (meeting) {
            console.info('meeting: ', meeting);
            if (meeting.index === meetingId) {
                uniqueId = meeting.uniqueMeetingId;
                startDate = meeting.startDate;
                startTime = meeting.startTime;
                endDate = meeting.endDate;
                endTime = meeting.endTime;
            }
        });
        console.info('Meeting uniqueId: ', uniqueId);
        this.updateMeetingUniqueId = uniqueId;

        let dt = new Date(startDate);
        let startTimeArr = startTime.split(':');
        dt.setHours(startTimeArr[0]);
        dt.setMinutes(startTimeArr[1]);

        let dtEnd = new Date(endDate);
        let endTimeArr = endTime.split(':');
        dtEnd.setHours(endTimeArr[0]);
        dtEnd.setMinutes(endTimeArr[1]);
        
        const miliisecNow = Date.now();
        const miliisecStart = dt.getTime();
        const miliisecEnd = dtEnd.getTime();

        if(miliisecNow < miliisecStart - 30*60000) {
            console.info('This meeting cannot be started earlier than 30 minutes before planning.');
            this.showToast('Error', 'This meeting cannot be started earlier than 30 minutes before planning.', 'error');
        } else if(miliisecNow > miliisecEnd) {
            console.info('The scheduled meeting is over. Create a new meeting.');
            this.showToast('Error', 'The scheduled meeting is over. Create a new meeting.', 'error');
        } else {
            // Log in as admin
            // Get AccessToken
            getAccessToken()
            .then(result => {
                console.info('result from CustomSettings response: ', result);
                const response = JSON.parse(result);
                this.accessToken = response.access_token;
                this.accountKey = response.account_key;

                this.loginData = {
                    accessToken : response.access_token,
                    accountKey : response.account_key
                };
                return this.loginData
            })
            .then(result => getUsers({data: result})
                .then(result => {
                    console.info('Users Result: ', JSON.parse(result).results);
                    let users = JSON.parse(result).results;

                    // Set users to variable
                    this.users = users;
                    return users;
                })
                .catch(error => {
                    this.showToast('Error getting users from GTM', 'error');
                    console.error('Error getting users data: ', error);
                    throw new Error('Error getting users from GTM');
                })
                .then(result => {
                    let matched = null;

                    // Set email
                    let currentUserEmail = '';
                    if (this.contactLogMeInEmail) {
                        currentUserEmail = this.contactLogMeInEmail;
                    } else {
                        const email = this.contactEmail;
                        console.info('User email: ', email);
                        if(email.includes('@ean.org')) {
                            // if email contains @ean.org
                            currentUserEmail = email;
                            console.info('Email includes @ean.org. Using email: ', currentUserEmail);
                        } else {
                            // if not
                            currentUserEmail = email.replace(/@/g,'.') + '@ean.org';
                            console.info('Email NOT includes @ean.org. Using email: ', currentUserEmail);
                        }
                    }

                    result.forEach(function (user) {
                        const userEmail = user.email;
                        if(userEmail === currentUserEmail) {
                            console.info('User matched: ', currentUserEmail);
                            matched = user;
                        }
                    });
                    // stored matched user or null
                    if(matched) {
                        this.matchedUser = matched;
                        return getLicenses({data: this.loginData});
                    } else {
                        console.info('User not matched: ', currentUserEmail);
                        this.matchedUser = null;
                        throw new Error('User not matched');
                    }
                    // return getLicenses({data: this.loginData});
                })
                .then(result => {
                    console.info('Licenses: ', JSON.parse(result).results);
                    const licenses = JSON.parse(result).results;
                    // Set license
                    this.license = licenses[0];

                    if(licenses[0].enabled) {
                        this.showToast('Success',
                            'Licenses successfully received. License is valid.',
                            'success');
                        this.license = licenses[0];
                    } else {
                        this.showToast('Success',
                            'Licenses successfully received. License is not activate.',
                            'error');
                    }
                    return result;
                })
                .catch(error => {
                    this.showToast('Error getting licenses', 'error');
                    console.error('Error getting licenses data: ', error);
                    throw new Error('Error getting licenses');
                }))
            .then(result=> {
                if(this.matchedUser) {

                    // ***** User is exist in LogMeIn *****
                    console.info('User is exist on GTM.');

                    this.startMeetingAsOwner(null);
                } else {

                    // ***** User is NOT exist in LogMeIn *****
                    console.error('User is not exist on GTM.');
                    this.showToast('User is not exist on GTM.', 'error');
                    throw new Error('User is not exist on GTM.');
                    // TODO: add logic if user is not exist
                }
            });
        }
    }

    /**
     *
     */
    startMeetingAsOwner() {
        // Set user key and email
        let userKey = '';
        let userEmail = '';
        if (this.matchedUser) {
            if (this.matchedUser.key) {
                userKey = this.matchedUser.key;
                console.info('Matched user key: ', userKey);
            }
            if (this.matchedUser.email) {
                userEmail = this.matchedUser.email;
                console.info('Matched user email: ', userEmail);
            }
        } else {
            console.error('No matched user');
        }

        // Create data for set license
        const data = {
            'userKey': userKey,
            'accessToken': this.loginData.accessToken,
            'accountKey': this.loginData.accountKey,
            'userEmail': userEmail,
            'licenceKey': this.license.key
        };
        console.info('setUserLicense data: ', data);
        // Save manage Licence Data
        this.manageLicenceData = data;

        // Set license for current user
        setUserLicense({data: data})
            .then(result=> {
                console.info('Set User License Successfully.');
                return result;
            })
            .catch(error=> {
                console.error('ERROR set User License: ', error);
                throw new Error('Set User License error');
            })
            .then(result=> {
                // Set data
                let email = '';
                if (this.contactLogMeInEmail) {
                    email = this.contactLogMeInEmail;
                } else {
                    email = userEmail;
                }
                const accessData = {
                    'userEmail': email,
                    'userPass': this.contactPass
                };
                console.info('Data for getAccessTokenAnyUser: ', accessData);
                // Activate User
                return getAccessTokenAnyUser({data: accessData});
            })
            .then(result=> {
                const myAuthenticationData = JSON.parse(result);

                // save current user
                this.currentUser = myAuthenticationData;
                console.info('getAccessTokenAnyUser: ', myAuthenticationData);
                return myAuthenticationData;
            })
            .catch(error=> {
                console.info('ERROR getAccessTokenAnyUser: ', error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                throw new Error('Set User License error');
            })
            .then(result=> {
                const data = {
                    'accountKey': result.account_key,
                    'accessToken': result.access_token
                };

                // GET Myself
                return getMyself({data: data});
            })
            .then(result=> {
                const myselfInfo = JSON.parse(result);
                this.myself = myselfInfo;
                console.info('Myself: ', myselfInfo);
                return myselfInfo;
            })
            .catch(error=> {
                console.error('ERROR Myself: ', error);
                this.deleteLicenceFromUser(this.manageLicenceData);
                throw new Error('Getting User data error');
            })
            // redirect to host URL
            .then(result=> {
                console.info('result.hostURL: ', this.hostURL);
                console.info('fullMeetingHistory: ',this.fullMeetingHistory);
                this.fullMeetingHistory.forEach((meeting)=> {

                    if (meeting.uniqueMeetingId === this.updateMeetingUniqueId) {
                        console.info('uniqueMeetingId is matched: ', meeting.uniqueMeetingId);
                        // behavior as clicking on a link
                        window.location.href = meeting.hostURL;
                    }
                });
            })
    }
}
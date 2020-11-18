({

  doInit: function(component, event, helper) {
    var settings = {
      colorAccent: 'rgb(221, 202, 0)',
      // colorAccent: 'rgb(246, 147, 124)',
    };

    document.documentElement.style.setProperty('--color-accent', settings.colorAccent);

    var page = {
      city: 'Oslo',
      year: '2019',
      count: '5',
      countPostfix: 'th',
      name: 'Congress of the European Academy of Neurolog',
      date: 'June 29 - Jule 2',
      wiFiName: 'EAN2019 Wifi_Biogen',
      wiFiSupportedBy: 'Biogen',
      appSupportedBy: 'Roche',
      appName: 'ean',
      appNumber: '20',
      certificateLink: 'www.ean.org/oslo2019',
      bookedTickets: [
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
        '(Diese Info kommt dann von dem Regi System)',
      ],
    };
    component.set('v.page', page);
  
    var badges = [
      {
        firstName: 'John',
        lastName: 'Doe',
        label: 'Succes Craft',
        labelType: 'danger',
        // city: 'Paris',
        // country: 'France',
        // barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Meeting only' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        label: 'Non-prescriber',
        labelType: 'danger',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Membership type' },
          { label: 'Faculty' },
          { label: 'ePoster presenter' },
          { label: 'ePresentation presenter' },
          { label: 'Panel Management Group Member' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        label: 'Non-prescriber',
        labelType: 'danger',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Full' },
          { label: 'Resident & Research Member' },
          { label: 'Corresponding' },
          { label: 'Associate Member' },
          { label: 'Fellow of the EAN' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        label: 'Non-prescriber',
        labelType: 'danger',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Student Member' },
          { label: 'Press' },
          { label: 'Tournament candidate' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        label: 'Non-prescriber',
        labelType: 'danger',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Tuesday, 5 September 2020', size: 'lg' },
        ],
      },
      {
        company: 'Succes Craft',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Non-Member' },
        ],
      },
      {
        company: 'Succes Craft',
        label: 'Group name',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Non-Member' },
        ],
      },
      {
        company: 'Succes Craft',
        label: 'Group name',
        labelType: 'danger',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Non-Member' },
        ],
      },
      {
        company: 'Succes Craft',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Full' },
          { label: 'Technical Staff' },
          { label: 'EAN Head Office' },
          { label: 'Student Member' },
          { label: 'Press' },
          { label: 'Tournament candidate' },
          { label: 'Membership type' },
          { label: 'Faculty' },
          { label: 'ePoster presenter' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Exhibitor', size: 'lg' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Technical Staff' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'Hostess' },
        ],
      },
      {
        firstName: 'John',
        lastName: 'Doe',
        city: 'Brest',
        country: 'Belarus',
        barcode: $A.get('$Resource.BadgeDetail') + '/barcode.svg',
        qrcode: $A.get('$Resource.BadgeDetail') + '/qr_code.png',
        footer: [
          { label: 'EAN Head Office' },
        ],
      },
    ];
    component.set('v.badges', badges);
  },

})
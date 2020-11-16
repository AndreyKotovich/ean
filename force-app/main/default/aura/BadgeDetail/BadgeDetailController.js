({
  doInit: function(component, event, helper) {
    var badge = JSON.parse(JSON.stringify(component.get('v.badge')));
    console.log(badge);

    var labelClass = 'badge_body_label';
    if (badge.labelType) {
      labelClass += ' font-color_' + badge.labelType;
    }
    component.set('v.labelClass', labelClass);

    var footerLines = [];

    badge.footer.forEach((item, index) => {
      var line = {
        lineClass: item.size
        ? 'badge_footer_line badge_footer_line-' + item.size
        : 'badge_footer_line',
        labelClass: 'badge_footer_label',
        label: item.label,
      };

      if (item.label == 'Membership type') {
        line.lineClass += ' background-color_membership-type';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Faculty') {
        line.lineClass += ' background-color_faculty';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'ePoster presenter') {
        line.lineClass += ' background-color_eposter-presenter';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'ePresentation presenter') {
        line.lineClass += ' background-color_epresentation-presenter';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Panel Management Group Member') {
        line.lineClass += ' background-color_panel-management-group-member';
        line.labelClass += ' font-color_dark';

      } else if (item.label == 'Meeting only') {
        line.lineClass += ' background-color_meeting-only';
        line.labelClass += ' font-color_dark';

      } else if (item.label == 'Non-Member') {
        line.lineClass += ' background-color_non-member';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Exhibitor') {
        line.lineClass += ' background-color_exhibitor';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Technical Staff') {
        line.lineClass += ' background-color_technical-staff';
        line.labelClass += ' font-color_dark';

      } else if (item.label == 'Hostess') {
        line.lineClass += ' background-color_hostess';
        line.labelClass += ' font-color_dark';

      } else if (item.label == 'EAN Head Office') {
        line.lineClass += ' background-color_ean-head-office';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Full') {
        line.lineClass += ' background-color_full';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Corresponding') {
        line.lineClass += ' background-color_corresponding';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Fellow of the EAN') {
        line.lineClass += ' background-color_fellow-of-the-ean';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Resident & Research Member') {
        line.lineClass += ' background-color_resident-research-member';
        line.labelClass += ' font-color_dark';

      } else if (item.label == 'Associate Member') {
        line.lineClass += ' background-color_associate-member';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Student Member') {
        line.lineClass += ' background-color_student-member';
        line.labelClass += ' font-color_white';

      } else if (item.label == 'Press') {
        line.lineClass += ' background-color_press';
        line.labelClass += ' font-color_dark';

      } else if (item.label == 'Tournament candidate') {
        line.lineClass += ' background-color_tournament-candidate';
        line.labelClass += ' font-color_white';

      } else {
        line.lineClass += ' background-color_date';
        line.labelClass += ' font-color_dark';
      }

      footerLines.push(line);
    });

    component.set('v.footerLines', footerLines);
  }
})
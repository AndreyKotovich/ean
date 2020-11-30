<aura:application access="global" controller="BadgeController" implements="lightning:isUrlAddressable,flexipage:availableForRecordHome,force:hasRecordId">

  <ltng:require styles="{!$Resource.BadgeDetail  + '/main.css'}"/>

  <!-- <aura:attribute name="page" type="Object"/> -->
  <aura:attribute name="id" type="String" />
  <aura:attribute name="badges" type="List"/>

  <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>

  <aura:iteration items="{!v.badges}" var="item">
    <!-- <c:BadgePage page="{!v.page}" badge="{!item}"/> -->
    <c:BadgePage badge="{!item}"/> 
  </aura:iteration>

</aura:application>
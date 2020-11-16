<aura:application access="global">

  <ltng:require styles="{!$Resource.BadgeDetail  + '/main.css'}"/>

  <aura:attribute name="page" type="Object"/>
  <aura:attribute name="badges" type="List"/>

  <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>

  <aura:iteration items="{!v.badges}" var="item">
    <c:BadgePage page="{!v.page}" badge="{!item}"/>
  </aura:iteration>

</aura:application>
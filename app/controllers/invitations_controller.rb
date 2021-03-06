class InvitationsController < ApplicationController
  #before_filter :authenticate_user!, :only => [:purge]
  before_filter :allowed_to_invite?, :only => [:invite]
    
  def create    
    invitations = params[:invitations].to_i
    items = params[:items].to_i
    
    redirect_to new_admin_invitation_path, :notice => I18n.t('messages.invitations.wrong_data') and return if (invitations <= 0  || items < 0)
    people = Person.with_items_more_than(items)
        unless people.empty?
          people.collect { |person| invitations.times {Invitation.create!(:inviter_person_id => person.id, :invitation_active => true)} }
        else
          Invitation.create!(:inviter_person_id => nil, :invitation_active => true)
        end
     redirect_to admin_invitations_path, :notice =>  I18n.t('messages.invitations.successfully_created')
  end
  
  def preview
    invitations = params[:invitations].to_i
    items = params[:items].to_i
    people = Person.with_items_more_than(items)
    people_count = people.count
    invitation_count = invitations * people_count
   respond_to do |format|
      format.html { redirection_rules(model_name) }
      format.json do
      
        render :json => { :success => true, :invites => invitation_count  }
      end
    end
  end
  
  def switch
    if Settings.invitations == 'false'
       Settings.invitations = 'true'
       authorised = Person.all
       authorised.each { |person| person.authorise! if person.has_email?}
    else 
       authorised = Person.all
       authorised.each do |person| 
         person.authorise! if person.has_email?
         puts "Person " + person.name + " authorised"
       end
       Settings.invitations = 'false'
    end
    redirect_to admin_dashboard_path
  end
  
  def validate
   redirect_to root_path, :notice => I18n.t('messages.invitations.account_locked') and return if current_user.locked?

   key = params[:key]
   unless key.empty?
     invitation = Invitation.find_by_invitation_unique_key(key)
     if !invitation.nil? && invitation.active?
        invitation.update_attributes(:invitee_person_id => current_user.person.id, :accepted_date => Time.now, :invitation_active => false)
        request = RequestedInvitation.find_by_user_id(current_user.id)
        request.accepted! unless request.nil?
        current_user.person.authorise!
        current_user.inform_mutural_friends(session[:fb_token])
        redirect_to next_policy_path and return
     end
   end 
   current_user.validation_failed!
   if current_user.locked?
     redirect_to root_path, :notice => I18n.t('messages.invitations.account_locked')
   else
     redirect_to root_path, :notice => I18n.t('messages.invitations.invalid_or_inactive_code')
   end
   
  end
  
  def purge
    if !current_user.locked?
      current_user.destroy
      session[:user_id] = nil
      redirect_to root_path
    else
      redirect_to root_path, :notice => I18n.t('messages.invitations.account_locked')
    end
  end
  
  def invite
     #Check if email format is proper
     if current_user.nil?
       inviter_id = nil
     else
       inviter_id = current_user.person.id
     end
     @invitation = Invitation.create!(:inviter_person_id => inviter_id, :invitation_active => true, :invitee_email => params[:email].to_s) unless params[:email].nil?
     begin
       UserMailer.invite_email(params[:email], @invitation.invitation_unique_key).deliver
       current_user.person.decrease_invitations! unless current_user.nil?
     rescue Exception => e
       puts "Email sending failed"
     end
     
     redirect_to_back
  end
  
  private
   
  def allowed_to_invite?
    #TODO: This would allow to hack into application and user who is not registered to pass a parameter to controller and use our email servers
    if current_user.nil?
      true #if admin
    else
      current_user.person.invitations_count == 0 ? false :true    
    end
  end
  
end

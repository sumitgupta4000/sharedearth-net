class ResourceNetwork < ActiveRecord::Base
  self.inheritance_column = "inheritance_type"

  TYPE_GIFTER_AND_POSSESSOR = 10.freeze
  TYPE_GIFTER = 20.freeze
  TYPE_POSSESSOR = 30.freeze
  TYPES = {
    TYPE_GIFTER_AND_POSSESSOR => "Gifter and Possessor",
    TYPE_GIFTER => "Gifter",
    TYPE_POSSESSOR => "Possessor"
  }

  validates_presence_of :type

   scope :item, lambda { |entity| where("resource_type_id =? AND resource_id = ?", EntityType::ITEM_ENTITY, entity.id) }
   scope :only_items, where(:resource_type_id => EntityType::ITEM_ENTITY)
   scope :entity, lambda { |entity| where("entity_id =? AND entity_type_id = ?", entity.id, EntityType::PERSON_ENTITY) }
   scope :entity_items, lambda { |entity| where("entity_id =? AND entity_type_id = ? AND resource_type_id =?", entity.id, EntityType::PERSON_ENTITY, EntityType::ITEM_ENTITY) }
   #scope :group_items, lambda { |entity| where("entity_id =? AND entity_type_id = ? AND resource_type_id =?", entity.id, EntityType::ENTITY_TYPES.invert[entity.class.name], EntityType::ITEM_ENTITY) }
   scope :group_items, lambda { |entity| where("entity_id =? AND entity_type_id = ? AND resource_type_id =?", entity.id, EntityType::VILLAGE_ENTITY, EntityType::ITEM_ENTITY) }
   scope :entities_items, lambda { |entities| where("entity_id in (?) AND entity_type_id = ? AND resource_type_id =?", entities, EntityType::VILLAGE_ENTITY, EntityType::ITEM_ENTITY) }
   scope :village_resources, lambda { |village_id | where("entity_id =? AND entity_type_id = ?", village_id, EntityType::VILLAGE_ENTITY)}
   scope :items, lambda { |items| where("resource_type_id=? AND resource_id in (?)", EntityType::ITEM_ENTITY, items)}
   scope :gifter, :conditions => { :type => TYPE_GIFTER }
   scope :possessor, :conditions => { :type => TYPE_POSSESSOR }
   scope :gifter_possessor, :conditions => { :type => TYPE_GIFTER_AND_POSSESSOR }

   def set_possessor!(entity, entity_type_id)
     self.entity_id = entity.id
     self.entity_type_id = entity_type_id
     self.type = TYPE_GIFTER
     save!
   end

   def remove_possessor!
     self.entity_id = nil
     self.type = TYPE_GIFTER_AND_POSSESSOR
     save!
   end

   def to_gifter!
     self.type = TYPE_GIFTER
     save!
   end

   def to_possessor!
     self.type = TYPE_POSSESSOR
     save!
   end

   def to_gifter_and_possessor!
     self.type = TYPE_GIFTER_AND_POSSESSOR
     save!
   end

   def self.items_belong_to(entity)
     resource_ids = self.group_items(entity).map(&:resource_id)
   	 Item.find_all_by_id(resource_ids)
   end
 
   def self.all_items_from(entities)
     items = []
     entities.each { |entity| entity.get_items.map{|i|items.push(i)} }
     items  
   end


end

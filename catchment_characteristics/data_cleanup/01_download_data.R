# Downloads all of the data below the item shown. One off, could be better.
# Saves a bunch of zip files wherever it gets kicked off.
library('sbtools')
children <- item_list_children('5669a79ee4b08895842a1d47')
urls<-sapply(children, function(child) child$title)
for(item in children) {
  children_children <- item_list_children(item$id)
  for(child_item in children_children) {
    try(item_file_download(child_item$id,dest_dir = './'))
    three_children <- item_list_children(child_item$id)
    if(length(three_children)>0){
      for(third_child in three_children) {
        try(item_file_download(third_child$id,dest_dir = './'))
      }
    }
  }
}
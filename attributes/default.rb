#
# Cookbook Name:: chef-compliance
# Attributes:: default
#

default['compliance']['version'] = '0.9.10'

default['compliance']['0.9.10']['rhel'] = {
		6 => { 'url' => 'https://packagecloud.io/chef/stable/packages/el/6/chef-compliance-0.9.10-1.el6.x86_64.rpm/download',
				 'sha1' => 'ab2ec6547b6fb70b4a7310a03b1cf9df2e9147b8' 
		},
		7 => { 'url' => 'https://packagecloud.io/chef/stable/packages/el/7/chef-compliance-0.9.10-1.el7.x86_64.rpm/download',
				 'sha1' => 'c0494becec6a9086c9f8cfd8ff783d4f775b9c19'

		}
 
}
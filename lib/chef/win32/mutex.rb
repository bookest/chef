#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/win32/api/synchronization'

class Chef
  module ReservedNames::Win32
    class Mutex
      include Chef::ReservedNames::Win32::API::Synchronization
      extend Chef::ReservedNames::Win32::API::Synchronization

      def initialize(name, initial_owner = true)
        @handle = CreateMutexW(nil, initial_owner, name)

        # Fail early if we can't get a handle to the named mutex
        if @handle.nil?
          Chef::Log.error("Failed to create system mutex with name'#{name}'")
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      attr_reader :handle

      #####################################################
      # Attempts to grab the mutex.
      # Returns true if the mutex is grabbed or if it's already
      # owned; false otherwise.
      def test
        WaitForSingleObject(handle, 0) == WAIT_OBJECT_0
      end

      #####################################################
      # Attempts to grab the mutex and waits until it is acquired.
      def wait
        if WaitForSingleObject(handle, INFINITE) != WAIT_OBJECT_0
          Chef::Log.error("Can not complete the wait for mutex '#{name}' successfully.")
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      #####################################################
      # Releaes the mutex
      def release
        unless ReleaseMutex(handle)
          # Don't fail things in here if we can't release the mutex.
          # Because it will be automatically released when the owner
          # of the process goes away and this class is only being used
          # to synchronize chef-clients runs on a node.
          Chef::Log.error("Can not release mutex '#{name}'. This might cause issues \
if the the mutex is attempted to be grabbed by other threads.")
        end
      end
    end
  end
end



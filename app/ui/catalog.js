/* Jiff Tweaks - action catalog. Each id is an engine action (see server.ps1 / engine). */
'use strict';

const RISK = {
  safe:       { label: 'Safe',          note: 'Low impact, easy to undo.' },
  moderate:   { label: 'Moderate',      note: 'Changes system behavior. Original values are saved.' },
  aggressive: { label: 'Aggressive',    note: 'Turns off features some apps rely on. Original values are saved.' },
  security:   { label: 'Security risk', note: 'Lowers protection. Only apply if you understand the trade-off.' },
  danger:     { label: 'Destructive',   note: 'Cannot be undone.' }
};

const GROUPS = [
  { id: 'dashboard', title: 'Dashboard',        icon: 'dashboard', sub: 'Overview of this PC and your changes.' },
  { id: 'optimize',  title: 'Performance',      icon: 'zap',       sub: 'Registry, scheduler, power plan and boot timer.' },
  { id: 'services',  title: 'Services',         icon: 'sliders',   sub: 'Turn off background services and scheduled tasks you do not need.' },
  { id: 'network',   title: 'Network',          icon: 'wifi',      sub: 'Lower latency: TCP settings, Nagle, adapter properties.' },
  { id: 'cleanup',   title: 'Debloat & Privacy', icon: 'trash',    sub: 'Remove preinstalled apps and switch off telemetry.' },
  { id: 'gpu',       title: 'GPU',              icon: 'monitor',   sub: 'Driver-level tweaks for NVIDIA and AMD.' },
  { id: 'expert',    title: 'Expert Lab',       icon: 'flask',     sub: 'Powerful changes that trade safety or features for speed.' },
  { id: 'restore',   title: 'Restore',          icon: 'restore',   sub: 'Put saved original values back.' },
  { id: 'logs',      title: 'Logs',             icon: 'file',      sub: 'Everything the engine did, line by line.' },
  { id: 'settings',  title: 'Settings',         icon: 'gear',      sub: 'Appearance and about.' }
];

/* page -> ordered action ids; the first id of a page may be flagged featured */
const PAGES = {
  optimize: ['reg_all', 'reg_system', 'reg_gaming', 'reg_input_ui', 'reg_priority', 'power_plan', 'devpower', 'bcd_timer'],
  services: ['svc_advanced', 'svc_standard', 'svc_basic', 'svc_xbox', 'tasks_disable'],
  network:  ['net_all', 'net_global', 'net_interfaces', 'nic_tweaks', 'net_reset'],
  cleanup:  ['privacy', 'debloat_curated', 'debloat_extended', 'debloat_onedrive'],
  gpu:      ['gpu_auto', 'nvidia_all', 'amd_all'],
  expert:   ['mitigations_off', 'defender_off', 'ntfs_tweaks', 'memcomp_off', 'power_delete_others', 'branding'],
  restore:  ['restore_all', 'restore_services', 'restore_tasks', 'restore_registry', 'restore_power', 'forget_originals']
};
const FEATURED = { optimize: 'reg_all', services: 'svc_advanced', network: 'net_all', gpu: 'gpu_auto', restore: 'restore_all' };

const CATALOG = {
  apply_full: {
    title: 'Full profile', icon: 'layers', risk: 'aggressive', reboot: true, steps: 11,
    short: 'Everything recommended in one run, with a restore point first.',
    does: [
      'Creates a Windows restore point',
      'Registry: latency, gaming, input and priority tweaks',
      'Services: advanced list plus per-user service templates',
      'Scheduled task cleanup',
      'Network: TCP settings, Nagle off, adapter properties',
      'JiffOS power plan, USB and device power saving off',
      'Privacy and telemetry policies',
      'GPU tweaks for the detected vendor, boot timer tweak',
      'Debloat: AppX apps and OneDrive uninstall'
    ],
    note: 'Defender and CPU mitigations are not touched. Removed apps are not restored by Restore.'
  },

  /* ---------- performance ---------- */
  reg_all: {
    title: 'All registry tweaks', icon: 'layers', risk: 'moderate', reboot: true,
    short: 'Latency, gaming, input and priority tweaks in one go.',
    tags: ['MMCSS', 'HAGS', 'Timers', 'Input', 'Priority'],
    does: ['Latency and scheduler', 'Gaming', 'Input and UI', 'CPU and I/O priority']
  },
  reg_system: {
    title: 'Latency and scheduler', icon: 'zap', risk: 'moderate', reboot: true,
    short: 'MMCSS game priority, GPU scheduling, timers, memory and shutdown timeouts.',
    tags: ['MMCSS', 'HAGS', 'TDR', 'Timers'],
    does: [
      'MMCSS: game task priority, network throttling off',
      'Win32PrioritySeparation 0x26, IRQ8 priority',
      'Hardware GPU scheduling on, TDR timeouts, MPO off',
      'Power throttling off, Fast Startup off, Connected Standby off',
      'Paging executive and paging combining off, timer resolution requests',
      'Shutdown and hung-app timeouts set to 1 second',
      'USB selective suspend off, NTFS last-access updates off'
    ]
  },
  reg_gaming: {
    title: 'Gaming', icon: 'gamepad', risk: 'safe', reboot: false,
    short: 'Game DVR off, fullscreen behavior and Game Mode.',
    tags: ['Game DVR', 'Fullscreen', 'Game Mode'],
    does: ['Game DVR and background capture off', 'Fullscreen optimizations follow the per-app setting', 'Game Mode on, Game Bar startup panel off']
  },
  reg_input_ui: {
    title: 'Input and UI', icon: 'mouse', risk: 'safe', reboot: false,
    short: '1:1 mouse input and snappier menus.',
    tags: ['No acceleration', 'Menu delay 0'],
    does: ['Pointer acceleration off', 'Menu show delay and hover time 0', 'Window and taskbar animations and transparency off']
  },
  reg_priority: {
    title: 'CPU and I/O priority', icon: 'cpu', risk: 'moderate', reboot: true,
    short: 'Keep background tasks out of the way of your game.',
    tags: ['Indexer', 'TrustedInstaller', 'Foreground boost'],
    does: ['Passive interrupt worker priority 18', 'Search Indexer, TrustedInstaller and wuauclt run at idle priority', 'Foreground boost decay off']
  },
  power_plan: {
    title: 'JiffOS power plan', icon: 'power', risk: 'moderate', reboot: false,
    short: 'Maximum-performance plan for AC power. Your plans are exported first.',
    tags: ['Ultimate', 'Core parking off', 'No sleep'],
    does: [
      'Built from Ultimate Performance, or imports JiffOSUltimate.pow when it is in the engine folder',
      'Processor 100% min and max, boost aggressive, core parking off',
      'Disk, USB, PCIe and Wi-Fi power saving off on AC',
      'Hibernate and Fast Startup off'
    ]
  },
  devpower: {
    title: 'USB and device power saving', icon: 'plug', risk: 'moderate', reboot: true,
    short: 'Stop Windows from suspending devices to save power.',
    tags: ['USB', 'PnP'],
    does: ['Selective suspend and idle power flags cleared on every device', '"Allow the computer to turn off this device" off', 'Original values are saved']
  },
  bcd_timer: {
    title: 'Boot timer', icon: 'clock', risk: 'moderate', reboot: true,
    short: 'Dynamic tick off and the TSC timer.',
    tags: ['bcdedit'],
    does: ['disabledynamictick set to yes', 'Platform clock override removed (uses TSC)']
  },

  /* ---------- services ---------- */
  svc_advanced: {
    title: 'Advanced services', icon: 'sliders', risk: 'aggressive', reboot: true,
    short: 'About 150 services plus per-user templates. The most aggressive tier.',
    tags: ['Update', 'Printing', 'Bluetooth', 'VPN', 'Hyper-V'],
    does: [
      'Turns off Windows Update, printing, Bluetooth, VPN, file sharing, Remote Desktop, Hyper-V and WSL2, Store licensing',
      'Per-user service templates (Bluetooth, CDP, OneSync, ...) disabled',
      'SamSs, Themes, TokenBroker and Defender are always kept',
      'Original start type of every service is saved'
    ]
  },
  svc_standard: {
    title: 'Standard services', icon: 'sliders', risk: 'moderate', reboot: true,
    short: 'Basic tier plus BITS, Remote Desktop, RAS and error reporting.',
    tags: ['BITS', 'RDP', 'WerSvc'],
    does: ['Everything in Basic', 'BITS, Remote Desktop, RAS, Error Reporting, Performance Logs', 'Original start types are saved']
  },
  svc_basic: {
    title: 'Basic services', icon: 'sliders', risk: 'safe', reboot: false,
    short: 'Telemetry, maps, search indexing, SysMain and time sync.',
    tags: ['DiagTrack', 'SysMain', 'WSearch'],
    does: ['Diagnostics, delivery optimization, push messaging', 'Maps, geolocation, offline files, retail demo', 'SysMain (Superfetch), Windows Search, Windows Time']
  },
  svc_xbox: {
    title: 'Xbox services', icon: 'gamepad', risk: 'moderate', reboot: false,
    short: 'Xbox Live auth, game save and networking services.',
    tags: ['Game Pass', 'Xbox'],
    does: ['XboxGipSvc, xbgm, XblAuthManager, XblGameSave, XboxNetApiSvc', 'Game Pass and Xbox sign-in stop working']
  },
  tasks_disable: {
    title: 'Scheduled task cleanup', icon: 'clock', risk: 'safe', reboot: false,
    short: 'Disable telemetry, CEIP, error reporting and maps tasks.',
    tags: ['About 35 tasks'],
    does: ['Compatibility Appraiser, CEIP, Disk Diagnostics, Feedback', 'Maps, Family Safety, Work Folders, Settings sync', 'Only enabled tasks are touched, and each is recorded for Restore']
  },

  /* ---------- network ---------- */
  net_all: {
    title: 'Full network tuning', icon: 'wifi', risk: 'moderate', reboot: true,
    short: 'TCP settings, Nagle off on every interface and adapter properties.',
    tags: ['TCP', 'Nagle', 'NIC'],
    does: ['TCP globals', 'Nagle off per interface', 'Adapter properties and power saving']
  },
  net_global: {
    title: 'TCP globals', icon: 'wifi', risk: 'safe', reboot: false,
    short: 'Autotuning normal, RSC off, ECN off, timestamps off.',
    tags: ['netsh', 'RSS', 'RSC'],
    does: ['Autotuning normal, RSS on, RSC off, ECN off, timestamps off', 'Teredo, 6to4 and ISATAP off', 'Network reservation 0%, Delivery Optimization peer sharing off']
  },
  net_interfaces: {
    title: 'Nagle off', icon: 'wifi', risk: 'safe', reboot: true,
    short: 'TcpAckFrequency and TCPNoDelay on every network interface.',
    tags: ['TcpAckFrequency', 'TCPNoDelay'],
    does: ['Writes the values under each interface GUID, not the parent key', 'Original keys are exported first']
  },
  nic_tweaks: {
    title: 'Adapter properties', icon: 'plug', risk: 'moderate', reboot: true,
    short: 'EEE, Green Ethernet, flow control, interrupt moderation and LSO off.',
    tags: ['EEE', 'LSO', 'Wake'],
    does: ['Only values your adapter already has are changed', 'Power saving and wake-on-LAN off', 'The adapter restarts briefly']
  },
  net_reset: {
    title: 'Network reset', icon: 'refresh', risk: 'moderate', reboot: true,
    short: 'Winsock and IP stack reset plus a DNS flush.',
    tags: ['winsock', 'ip reset'],
    does: ['netsh winsock reset, netsh int ip reset, ipconfig /flushdns', 'Clears static IP settings and VPN adapters may need re-adding']
  },

  /* ---------- debloat and privacy ---------- */
  privacy: {
    title: 'Privacy and telemetry', icon: 'eye', risk: 'safe', reboot: false,
    short: 'Telemetry, ads, suggestions and error reporting off.',
    tags: ['Telemetry', 'Ads', 'Cortana'],
    does: [
      'Telemetry policy 0, feedback prompts and OneSettings downloads off',
      'Bing search, activity feed, advertising ID and tailored experiences off',
      'Windows Error Reporting off',
      'Consumer features and suggested apps off',
      'Telemetry scheduled tasks disabled'
    ]
  },
  debloat_curated: {
    title: 'Consumer apps', icon: 'trash', risk: 'moderate', reboot: false,
    short: 'Weather, Maps, Solitaire, People, Feedback Hub and similar.',
    tags: ['AppX'],
    does: ['Removes about 22 preinstalled apps for all users', 'Includes Xbox overlay and identity packages', 'Can be reinstalled from the Microsoft Store. Not covered by Restore']
  },
  debloat_extended: {
    title: 'Extended apps', icon: 'trash', risk: 'aggressive', reboot: false,
    short: 'Teams, Copilot, Clipchamp, Bing apps, Mail and Calendar and more.',
    tags: ['Teams', 'Copilot', 'Clipchamp'],
    does: ['Removes about 25 more apps including Teams, Copilot, Clipchamp, Mail, Dev Home and the Bing apps', 'Game Pass and Xbox sign-in stop working', 'Can be reinstalled from the Microsoft Store. Not covered by Restore']
  },
  debloat_onedrive: {
    title: 'Uninstall OneDrive', icon: 'trash', risk: 'moderate', reboot: false,
    short: 'Removes OneDrive. Your OneDrive folder is kept.',
    tags: ['OneDrive'],
    does: ['Uninstalls OneDrive and blocks sync by policy', 'Your OneDrive folder is only removed if it is empty']
  },

  /* ---------- gpu ---------- */
  gpu_auto: {
    title: 'Auto (detected GPU)', icon: 'monitor', risk: 'moderate', reboot: true,
    short: 'Applies the right tweaks for the GPU vendor found in this PC.',
    tags: ['NVIDIA', 'AMD'],
    does: ['NVIDIA adapters get the NVIDIA tweaks', 'AMD adapters get the AMD tweaks', 'Other GPUs are skipped']
  },
  nvidia_all: {
    title: 'NVIDIA', icon: 'monitor', risk: 'moderate', reboot: true, vendor: 'nvidia',
    short: 'HDCP off, P-state lock and telemetry off.',
    tags: ['HDCP', 'P-state', 'Telemetry'],
    does: ['HDCP off (some protected video may not play)', 'P-state lock to the highest state, higher idle power', 'NVIDIA telemetry service and tasks off']
  },
  amd_all: {
    title: 'AMD', icon: 'monitor', risk: 'moderate', reboot: true, vendor: 'amd',
    short: 'Adrenalin, ReLive, Radeon Boost, Chill, Anti-Lag and driver defaults.',
    tags: ['Adrenalin', 'ReLive', 'KMD', 'UMD'],
    does: ['Adrenalin auto-update, tray and toasts off', 'ReLive and DVR off', 'Radeon Boost, Chill, Anti-Lag and USU off', 'Driver UMD and DXVA defaults, AMD crash and events services off']
  },

  /* ---------- expert ---------- */
  mitigations_off: {
    title: 'CPU and OS mitigations off', icon: 'shield', risk: 'security', reboot: true,
    short: 'Spectre and Meltdown, SEHOP, CFG and VBS/HVCI switched off.',
    tags: ['Spectre', 'CFG', 'VBS'],
    does: ['Spectre and Meltdown mitigations off', 'SEHOP, CFG and process mitigations off', 'Memory integrity (VBS / HVCI) off'],
    note: 'Lowers system security. Reboot required.'
  },
  defender_off: {
    title: 'Disable Windows Defender', icon: 'shield', risk: 'security', reboot: true,
    short: 'Real-time protection, SmartScreen and Defender services off.',
    tags: ['Defender', 'SmartScreen'],
    does: ['Turn Tamper Protection off in Windows Security first, otherwise Windows blocks this', 'Policies and Set-MpPreference: real-time, behavior and cloud protection off', 'Defender and Security Center services disabled'],
    note: 'Your PC has no antivirus afterward unless you install one.'
  },
  ntfs_tweaks: {
    title: 'NTFS tweaks', icon: 'file', risk: 'moderate', reboot: false,
    short: 'Memory usage, MFT zone, last-access off, TRIM on.',
    tags: ['fsutil'],
    does: ['memoryusage 2, mftzone 4', 'Last-access updates off, delete notify (TRIM) on', 'Paging file encryption off']
  },
  memcomp_off: {
    title: 'Memory compression off', icon: 'cpu', risk: 'moderate', reboot: true,
    short: 'Disable memory compression and page combining.',
    tags: ['MMAgent'],
    does: ['Disable-MMAgent -MemoryCompression -PageCombining', 'Uses more RAM. Best with 16 GB or more']
  },
  power_delete_others: {
    title: 'Delete other power plans', icon: 'trash', risk: 'moderate', reboot: false,
    short: 'Keep only the JiffOS plan. Originals are exported first.',
    tags: ['powercfg'],
    does: ['Requires the JiffOS plan to be active', 'Every other plan is exported, then deleted', 'Restore brings the plans back']
  },
  branding: {
    title: 'JiffOS branding', icon: 'sparkle', risk: 'safe', reboot: false,
    short: 'Wallpaper, lock screen, accent, system info and PC name.',
    tags: ['Wallpaper', 'Theme'],
    does: ['Downloads the JiffOS wallpaper, sets lock screen and dark accent theme', 'Renames This PC, boot entry and the C: label, sets the PC name to JIFFOS-PC', 'Adds system info logo and a desktop shortcut']
  },

  /* ---------- restore ---------- */
  restore_all: {
    title: 'Restore everything', icon: 'restore', risk: 'safe', reboot: true,
    short: 'Services, tasks, registry, device flags and power plans back to the saved originals.',
    tags: ['Services', 'Registry', 'Tasks', 'Power'],
    does: ['Services return to their original start types', 'Registry keys are re-imported and values the tweaks created are deleted', 'Scheduled tasks and power plans are restored', 'Removed apps are not reinstalled']
  },
  restore_services: {
    title: 'Restore services', icon: 'restore', risk: 'safe', reboot: true,
    short: 'Original start types for every service that was changed.', tags: ['Services'],
    does: ['Writes the saved Start value back for each service']
  },
  restore_tasks: {
    title: 'Restore scheduled tasks', icon: 'restore', risk: 'safe', reboot: false,
    short: 'Re-enable every task the tweaks disabled.', tags: ['Tasks'],
    does: ['Enables each task recorded by the cleanup']
  },
  restore_registry: {
    title: 'Restore registry', icon: 'restore', risk: 'safe', reboot: true,
    short: 'Re-import saved keys and delete values that were added.', tags: ['Registry'],
    does: ['Saved .reg exports are imported, parents first', 'Values that did not exist before are deleted']
  },
  restore_power: {
    title: 'Restore power plans', icon: 'restore', risk: 'safe', reboot: false,
    short: 'Bring back your original power plans and active plan.', tags: ['Power'],
    does: ['Exported plans are re-imported', 'Your original active plan is selected, JiffOS plan removed']
  },
  forget_originals: {
    title: 'Forget saved originals', icon: 'trash', risk: 'danger', reboot: false,
    short: 'Deletes every backup. Restore can no longer go back to the original state.', tags: ['Backups'],
    does: ['Deletes all saved originals', 'The next change saves a new baseline from the current state'],
    note: 'This cannot be undone.'
  }
};

/* inline icon set (24x24, stroke) */
const ICONS = {
  dashboard: '<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
  zap: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>',
  sliders: '<line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/>',
  wifi: '<path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/>',
  trash: '<polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>',
  eye: '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>',
  cpu: '<rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/>',
  monitor: '<rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/>',
  flask: '<path d="M9 3h6"/><path d="M10 3v6.5L4.5 19a1.5 1.5 0 0 0 1.3 2.2h12.4a1.5 1.5 0 0 0 1.3-2.2L14 9.5V3"/><path d="M7.5 15h9"/>',
  restore: '<polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/>',
  file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>',
  gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
  power: '<path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/>',
  plug: '<path d="M12 22v-5"/><path d="M9 8V2"/><path d="M15 8V2"/><path d="M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8z"/>',
  clock: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  mouse: '<path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z"/><path d="M13 13l6 6"/>',
  gamepad: '<line x1="6" y1="12" x2="10" y2="12"/><line x1="8" y1="10" x2="8" y2="14"/><line x1="15" y1="13" x2="15.01" y2="13"/><line x1="18" y1="11" x2="18.01" y2="11"/><rect x="2" y="6" width="20" height="12" rx="3"/>',
  check: '<polyline points="20 6 9 17 4 12"/>',
  x: '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
  alert: '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>',
  play: '<polygon points="6 3 20 12 6 21 6 3"/>',
  stop: '<rect x="6" y="6" width="12" height="12" rx="1.5"/>',
  refresh: '<polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>',
  layers: '<polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/>',
  database: '<ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/>',
  sparkle: '<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/><path d="M19 17l.7 1.8L21.5 19.5l-1.8.7L19 22l-.7-1.8-1.8-.7 1.8-.7z"/>',
  info: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>',
  arrow: '<line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>',
  skip: '<line x1="5" y1="12" x2="19" y2="12"/>'
};

function icon(name, cls) {
  return '<svg class="ic ' + (cls || '') + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (ICONS[name] || '') + '</svg>';
}

// Format staged sources only. Framework/SwiftyUpdateKit.xcframework/ is a
// generated distribution artifact: running uncrustify over its generated
// headers reorders their #include lines and invalidates the bundle signature,
// so the formatters must never see it.
const GENERATED = 'Framework/SwiftyUpdateKit.xcframework/'

const format = (command) => (files) => {
  const targets = files.filter((file) => !file.includes(GENERATED))
  return targets.length ? [`${command} ${targets.map((f) => `'${f}'`).join(' ')}`] : []
}

module.exports = {
  '**/*.swift': format('./.codeformat/swiftformat'),
  '**/*.{m,h}': format('./.codeformat/uncrustify -c uncrustify-objc.cfg --no-backup -l OC'),
}

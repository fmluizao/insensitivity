class String
  #emprestado do brazilian-rails
  unless respond_to? :remover_acentos
    def remover_acentos
      texto = self
      return texto if texto.blank?
      texto = texto.gsub(/[á|à|ã|â|ä]/, 'a').gsub(/(é|è|ê|ë)/, 'e').gsub(/(í|ì|î|ï)/, 'i').gsub(/(ó|ò|õ|ô|ö)/, 'o').gsub(/(ú|ù|û|ü)/, 'u')
      texto = texto.gsub(/(Á|À|Ã|Â|Ä)/, 'A').gsub(/(É|È|Ê|Ë)/, 'E').gsub(/(Í|Ì|Î|Ï)/, 'I').gsub(/(Ó|Ò|Õ|Ô|Ö)/, 'O').gsub(/(Ú|Ù|Û|Ü)/, 'U')
      texto = texto.gsub(/ñ/, 'n').gsub(/Ñ/, 'N')
      texto = texto.gsub(/ç/, 'c').gsub(/Ç/, 'C')
      texto
    end
  end
end
